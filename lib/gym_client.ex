defmodule GymClient do
  @moduledoc ~S"""
  Quick-n-Dirty™ implementation of the relevant REST API calls for:
  https://github.com/saravanabalagi/gym-http-server
  """

  @doc ~S"""
  Create an instance of the specified environment
  """
  def create_env(env_id) do
    "/v1/envs/"
    |> GymClient.Api.post(%{env_id: env_id})
    |> (fn {200, %{instance_id: instance_id}} -> instance_id end).()
  end

  @doc ~S"""
  List all environments running on the server
  """
  def get_envs() do
    "/v1/envs/"
    |> GymClient.Api.get()
    |> (fn {200, %{all_envs: envs}} -> envs end).()
  end

  @doc ~S"""
  Reset the state of the environment and return an initial observation.
  """
  def reset_env(instance_id) do
    "/v1/envs/" <> instance_id <> "/reset/"
    |> GymClient.Api.post()
    |> (fn {200, %{observation: observation}} -> observation end).()
  end

  @doc ~S"""
  Step though an environment using an action
  """
  def step(instance_id, action, render \\ true) do
    "/v1/envs/" <> instance_id <> "/step/"
    |> GymClient.Api.post(%{action: action, render: render})
    |> (fn {200, resp} -> resp end).()
  end

  @doc ~S"""
  Get information (name and dimensions/bounds) of the env's `action_space`
  """
  def action_space(instance_id) do
    "/v1/envs/" <> instance_id <> "/action_space/"
    |> GymClient.Api.get()
    |> (fn {200, %{info: info}} -> info end).()
  end

  @doc ~S"""
  Get information (name and dimensions/bounds) of the env's `observation_space`
  """
  def observation_space(instance_id) do
    "/v1/envs/" <> instance_id <> "/observation_space/"
    |> GymClient.Api.get()
    |> (fn {200, %{info: info}} -> info end).()
  end

end
