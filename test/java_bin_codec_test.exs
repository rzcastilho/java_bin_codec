defmodule JavaBinCodecTest do
  use ExUnit.Case
  doctest JavaBinCodec

  test "greets the world" do
    assert JavaBinCodec.hello() == :world
  end
end
