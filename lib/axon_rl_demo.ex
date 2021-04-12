defmodule AxonRLDemo do
  @moduledoc """
  Documentation for `AxonRLDemo`.
  """

  import GymClient

  @max_episodes 5000

  def run() do
    env = create_env("CartPole-v1")
#    env = create_env("LunarLander-v2")
    num_actions = action_space(env) |> IO.inspect() |> Map.get(:n)
    num_states = GymClient.observation_space(env) |> IO.inspect() |> Map.fetch!(:shape) |> hd()
    agent = GymAgent.new(num_states: num_states, num_actions: num_actions, eps: 0.25, eps_decay: 0.995, gamma: 0.99)
#    exit(:normal)
    run_experiment(agent, env, @max_episodes)
  end

  def run_experiment(agent, _env, 0 = _episodes_left), do: agent

  def run_experiment(agent, env, episodes_left) do
    run_episode(agent, env, episodes_left)
    |> run_experiment(env, episodes_left - 1)
  end

  def run_episode(agent, env, episodes_left) do
    s = reset_env(env)
    agent = GymAgent.querysetstate(agent, s)
    %{agent: agent, r: r, steps: steps} = exec_step(agent, env, false, 0.0, 1)
    IO.puts("Episode " <> Integer.to_string(@max_episodes - episodes_left) <> " finished after " <> Integer.to_string(steps) <> " timesteps" <>
            "; r = " <> Float.to_string(r) <>
            "; eps = " <> Float.to_string(agent.eps)
    )
    agent
  end

  defp exec_step(agent, _env, true = done, r, steps) do
    %{agent: agent, done: done, r: r, steps: steps - 1}
  end

  defp exec_step(agent, env, _done, _r, steps) do
    %{observation: s_prime, reward: r, done: done, info: _info} = step(env, agent.a)
#    |> IO.inspect()

    # Ensure all values are floats
    s_prime = Enum.map(s_prime, fn x -> x /1 end)
    r = r / 1

    GymAgent.query(agent, r, s_prime, done)
    |> exec_step(env, done, r, steps + 1)
  end

end
