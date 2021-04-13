defmodule GymAgent do
  @moduledoc false

  require Axon
  import Nx.Defn

  alias GymAgent.Experience

  @batch_size 64
  @history_size_min 100
  @history_size_max 50_000

  defstruct [
    num_actions: 0,
    num_states: 0,
    state_norms: nil,
    gamma: 0.99,
    eps: 0.99,
    eps_decay: 0.99,
    learner: nil,
    fit: false,
    trained: false,
    history: nil,
    s: nil,
    a: nil
  ]

  def new(opts \\ []) do
    agent = %GymAgent{}
    # Default overridable options
    |> struct(opts)

    # Force defaults for internal items
    |> struct(fit: false)
    |> struct(trained: false)
    |> struct(history: Deque.new(@history_size_max))

    # Continue updating agent based on initialization params
    agent
    |> struct(learner: create_learner(agent))
  end

  def querysetstate(agent, s) do
    s_norm = if agent.state_norms == nil, do: s, else: calc_normalized_states(s, agent.state_norms)
    agent
    |> update_state(s_norm)
    |> update_action(get_action(agent, s_norm))
    |> decay_eps()
  end

  def query(agent, r, s_prime, done) do
    agent
    |> update_q(r, s_prime, done)
    |> train()
  end

  defp calc_normalized_states(s, norms) do
    s
    |> Enum.zip(norms)
    |> Enum.map(fn {x, y} -> x / y end)
  end

  defp create_learner(agent) do
    k_init = :uniform
    h1 = agent.num_states * 10
    model =
      Axon.input({nil, agent.num_states})
      |> Axon.dense(h1, kernel_initializer: k_init, activation: :tanh)
      |> Axon.dense(agent.num_actions, kernel_initializer: k_init, activation: :linear)
      |> IO.inspect()

    params = Axon.init(model, compiler: EXLA)

    {model, {params, Nx.tensor(0.0)}}
  end

  defp update_q(agent, r, s_prime, done) do
    a_prime = get_action(agent, s_prime)
    xp = %Experience{s: agent.s, a: agent.a, r: r, s_prime: s_prime, done: done}

    agent
    |> update_history(xp)
    |> update_action(a_prime)
    |> update_state(s_prime)
  end

  defp update_state(agent, s) do
    struct(agent, s: s)
  end

  defp update_action(agent, a) do
    struct(agent, a: a)
  end

  defp update_history(agent, xp) do
    struct(agent, history: Deque.append(agent.history, xp))
  end

  defp train(%GymAgent{trained: true} = agent), do: agent

  defp train(%GymAgent{trained: false, learner: {model, model_state}} = agent) do
    fit = Enum.count(agent.history) >= @history_size_min
    case fit do
      true ->
          xp_samples = Enum.take_random(agent.history, @batch_size)
          train_samples = xp_samples
          |> Enum.map(fn x -> x.s end)
          |> Nx.tensor()
          |> Nx.to_batched_list(@batch_size)

          train_labels = gen_data_labels(xp_samples, agent)
          |> Nx.tensor()
          |> Nx.to_batched_list(@batch_size)

          model_state = model
            |> AxonRLDemo.Training.step(model_state, :mean_squared_error, Axon.Optimizers.adamw(0.005))
            |> AxonRLDemo.Training.train(train_samples, train_labels, epochs: 1, compiler: EXLA)

          agent
          |> struct(learner: {model, model_state})
          |> struct(fit: fit)
      _ -> agent
    end
  end

  defp gen_data_labels([], _), do: []

  defp gen_data_labels([xp | samples], agent) do
    v = get_values(agent, xp.s) |> Nx.to_flat_list()
    vr = if xp.done, do: xp.r, else: calc_r(xp.r, agent.gamma, get_values(agent, xp.s_prime))
    labels = List.replace_at(v, xp.a, Nx.to_scalar(vr))
    [labels | gen_data_labels(samples, agent)]
  end

  defnp calc_r(r, gamma, values) do
    r + (gamma * Nx.reduce_max(values))
  end

  defp get_action(%GymAgent{fit: false} = agent, _s) do
    get_random_action(agent)
  end

  defp get_action(%GymAgent{fit: true} = agent, s) do
    cond do
      :rand.uniform_real() <= agent.eps -> get_random_action(agent)
      true -> get_learned_action(agent, s)
    end
  end

  defp get_learned_action(agent, s) do
    get_values(agent, s) |> Nx.argmax() |> Nx.to_scalar()
  end

  defp get_random_action(agent) do
    Nx.random_uniform(1, 0, agent.num_actions) |> Nx.to_scalar()
    #:rand.uniform(agent.num_actions) - 1
  end

  defp decay_eps(%GymAgent{fit: true} = agent) do
    eps = agent.eps * agent.eps_decay
    struct(agent, eps: eps)
  end

  defp decay_eps(%GymAgent{fit: false} = agent), do: agent

  defp get_values(%GymAgent{fit: false} = agent, _s) do
    Nx.random_uniform({agent.num_actions})
    #for _ <- 1..agent.num_actions, do: :rand.uniform()
  end

  defp get_values(%GymAgent{fit: true, learner: {model, model_state}}, s) do
    inputs = Nx.tensor(s) |> Nx.new_axis(0)
    {params, _} = model_state
    Axon.predict(model, params, inputs, compiler: EXLA)
  end

end
