defmodule Klf200.SlipTest do
  use ExUnit.Case
  alias Klf200.Slip

  doctest Slip

  test "packs correctly" do
    assert Slip.pack("test") == <<192, 116, 101, 115, 116, 192>>
  end

  test "packs and unpacks" do
    assert "test" |> Slip.pack() |> Slip.unpack() == "test"
  end

  test "escapes and unescapes" do
    assert Base.decode16!("DB") |> Slip.pack() |> Slip.unpack() == Base.decode16!("DB")
  end
end
