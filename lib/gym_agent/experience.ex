defmodule GymAgent.Experience do
  @moduledoc false

  @enforce_keys [:s, :a, :r, :s_prime, :done]
  defstruct [:s, :a, :r, :s_prime, :done]

end
