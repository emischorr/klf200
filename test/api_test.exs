defmodule Klf200.ApiTest do
  use ExUnit.Case
  alias Klf200.Api

  doctest Api

  describe "API.response()" do
    test "should decode GW_PASSWORD_ENTER_CFM correctly" do
      assert Api.response(<<192, 0, 4, 48, 1, 0, 53, 192>>) ==
               {:ok, %{frame: :GW_PASSWORD_ENTER_CFM, payload: :ok}}
    end

    test "should decode GW_GET_VERSION_CFM correctly" do
      assert Api.response(<<192, 0, 12, 0, 9, 0, 2, 0, 0, 71, 0, 6, 14, 3, 75, 192>>) ==
               {:ok,
                %{
                  frame: :GW_GET_VERSION_CFM,
                  payload: %{hardware: <<6>>, software: <<0, 2, 0, 0, 71, 0>>}
                }}
    end
  end
end
