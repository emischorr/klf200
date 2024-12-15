defmodule Klf200 do
  @moduledoc """
  Documentation for `Klf200`.
  """

  @doc """
  Connect to KLF 200 device

  """
  def connect(ip, pw) do
    {:ok, _pid} = Klf200.Client.start_link()
    :ok = Klf200.Client.connect(ip)
    :ok = Klf200.Client.login(pw)
    Klf200.Client.command(:GW_GET_ALL_NODES_INFORMATION_REQ)
  end

  def nodes() do
    Klf200.Client.command(:GW_GET_ALL_NODES_INFORMATION_REQ)
    Klf200.Client.nodes()
  end

  def position(%{node: node}, pos) when is_integer(node) and is_integer(pos), do: position(node, pos)

  def position(node, pos) when is_integer(node) and is_integer(pos) do
    Klf200.Client.command(:GW_COMMAND_SEND_REQ, %{node: node, position: pos})
  end
end
