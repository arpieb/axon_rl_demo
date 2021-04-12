defmodule AxonRLDemoTest do
  use ExUnit.Case
  doctest AxonRLDemo

  test "greets the world" do
    assert AxonRLDemo.hello() == :world
  end
end
