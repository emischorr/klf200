defmodule Klf200.Device do
  @moduledoc """
  This module abstracts a klf200 device as it connects to a specified GW IP,
  query for nodes and the internal state and keeps that information in the process state.

  It starts a GenServer for that and uses the Client module to manage a connection to the GW.
  """
  use GenServer
  alias Klf200.Client

  # API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  # Callbacks

  @impl GenServer
  def init(_opts) do
    {:ok, _pid} = Client.start_link()
    {:ok, %{nodes: []}}
  end
end
