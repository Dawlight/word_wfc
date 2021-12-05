defmodule WordWFCTest do
  use ExUnit.Case
  doctest WordWFC

  test "greets the world" do
    assert WordWFC.hello() == :world
  end
end
