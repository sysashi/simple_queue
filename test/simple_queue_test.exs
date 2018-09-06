defmodule SQTest do
  use ExUnit.Case
  doctest SQ

  test "greets the world" do
    assert SQ.hello() == :world
  end
end
