defmodule TwitterEngineTest do
  use ExUnit.Case
  doctest TwitterEngine

  test "greets the world" do
    assert TwitterEngine.hello() == :world
  end
end
