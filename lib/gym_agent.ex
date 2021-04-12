defmodule GymAgent do
  @moduledoc false

  require Axon

  alias GymAgent.Experience

  @batch_size 10
  @history_size_min 100
  @history_size_max 10_000

  defstruct num_actions: 0, num_states: 0, gamma: 0.99, eps: 0.25, eps_decay: 0.99, learner: nil, fit: false, trained: false, history: nil, s: nil, a: nil

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

  def create_learner(agent) do
    hidden_size = agent.num_states * 10
    model =
      Axon.input({nil, agent.num_states})
      |> Axon.dense(hidden_size, activation: :tanh)
      |> Axon.dense(agent.num_actions, activation: :linear)
      |> IO.inspect()

    params = Axon.init(model)#, compiler: EXLA)

    {model, {params, Nx.tensor(0.0)}}
  end

  def querysetstate(agent, s) do
    agent
    |> update_state(s)
    |> update_action(get_action(agent, s))
    |> decay_eps()
  end

  def query(agent, r, s_prime, done) do
    agent
    |> update_q(r, s_prime, done)
    |> train()
  end

  def update_q(agent, r, s_prime, done) do
    a_prime = get_action(agent, s_prime)
    xp = %Experience{s: agent.s, a: agent.a, r: r, s_prime: s_prime, done: done}

    agent
    |> update_history(xp)
    |> update_action(a_prime)
    |> update_state(s_prime)
  end

  def update_state(agent, s) do
    struct(agent, s: s)
  end

  def update_action(agent, a) do
    struct(agent, a: a)
  end

  def update_history(agent, xp) do
    struct(agent, history: Deque.append(agent.history, xp))
  end

  def train(%GymAgent{trained: true} = agent), do: agent

  def train(%GymAgent{trained: false, learner: {model, model_state}} = agent) do
    fit = Enum.count(agent.history) >= @history_size_min
    case fit do
      true ->
          xp_samples = Enum.take_random(agent.history, @batch_size)
          train_samples = xp_samples
          |> Enum.map(fn x -> x.s end)
          |> Nx.tensor()

          train_labels = gen_data_labels(xp_samples, agent)
          |> Nx.tensor()

          {_init_fn, step_fn} = Axon.Training.step(model, :mean_squared_error, Axon.Optimizers.adamw(0.005))
          {model_state, _batch_loss} = step_fn.(model_state, train_samples, train_labels)
          #{model_state, _batch_loss} = Nx.Defn.jit(step_fn, [model_state, train_samples, train_labels])

          agent
          |> struct(learner: {model, model_state})
          |> struct(fit: fit)
      _ -> agent
    end
  end

  def gen_data_labels([], _), do: []

  def gen_data_labels([xp | samples], agent) do
    v = get_values(agent, xp.s)
    vr = if xp.done, do: xp.r, else: (xp.r + (agent.gamma * Enum.max(get_values(agent, xp.s_prime))))
    labels = List.replace_at(v, xp.a, vr)
    [labels | gen_data_labels(samples, agent)]
  end

  def get_action(%GymAgent{fit: false} = agent, _s) do
    get_random_action(agent)
  end

  def get_action(%GymAgent{fit: true} = agent, s) do
    cond do
      :rand.uniform_real() <= agent.eps -> get_random_action(agent)
      true -> get_learned_action(agent, s)
    end
  end

  def get_learned_action(agent, s) do
    get_values(agent, s)
    |> argmax()
  end

  def get_random_action(agent) do
    :rand.uniform(agent.num_actions) - 1
  end

  def decay_eps(%GymAgent{fit: true} = agent) do
    eps = agent.eps * agent.eps_decay
    struct(agent, eps: eps)
  end

  def decay_eps(%GymAgent{fit: false} = agent), do: agent

  def get_values(%GymAgent{fit: false} = agent, _s) do
    for _ <- 1..agent.num_actions, do: :rand.uniform()
  end

  def get_values(%GymAgent{fit: true, learner: {model, {params, _}}}, s) do
    Axon.predict(model, params, s)#, compiler: EXLA)
  end

  def argmax(values) do
    red_values = values |> Enum.with_index()
    red_values |> Enum.reduce(hd(red_values), &reduce_argmax/2) |> elem(1)
  end

  defp reduce_argmax({val, idx}, {acc_val, acc_idx}), do: if (val > acc_val), do: {val, idx}, else: {acc_val, acc_idx}

end
