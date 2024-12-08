defmodule Klf200.Client do
  @moduledoc """
  A client process that uses the API module to start a session with a VELUX klf200 GW.
  This module handles the socket and connection layer (inlcuding SSL and session authentication).
  It also keeps track of the state of the session (logged in? which confirmations are expected at the current step?) and forwards messages back to caller.

  It provides a generic function to send commands as well as specific functions to initialize the connection.
  """

  use GenServer
  alias Klf200.Api
  alias Klf200.Client.SSL_Helper

  @klf_cert "klf-cert.pem"
  @klf_ssl_fingerprint "028C23A0892B6298C499005BD2E72E0A703D716A"
  @socket_opts [
    packet: :raw,
    authorities: [path: @klf_cert],
    verify: [function: &SSL_Helper.verify_fun/3, data: {:sha, @klf_ssl_fingerprint}]
  ]
  @klf_port 51200

  # API
  def start_link(opts \\ []) do
    # TODO: switch to dynamic naming
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def connect(host) do
    GenServer.call(__MODULE__, {:connect, host})
  end

  def login(password) do
    GenServer.call(__MODULE__, {:login, password})
  end

  def nodes, do: GenServer.call(__MODULE__, :nodes)

  def command(cmd), do: command(cmd, %{})

  def command(cmd, data) do
    GenServer.call(__MODULE__, {:command, cmd, data})
  end

  # Callbacks

  @impl GenServer
  def init(_opts) do
    {:ok, %{socket: nil, logged_in: nil, waiting_client: nil, waiting_for_frame: nil, next_session: 0, nodes: %{}}}
  end

  @impl GenServer
  def handle_call({:connect, host}, _from, state) do
    case Socket.SSL.connect({host, @klf_port}, @socket_opts) do
      {:ok, socket} ->
        IO.puts("Connection established. Listening...")
        {:ok, _pid} = Task.start_link(fn -> listen(socket) end)
        {:reply, :ok, %{state | socket: socket}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def handle_call({:login, password}, _from, state) do
    return = Socket.Stream.send(state.socket, Api.request(:GW_PASSWORD_ENTER_REQ, %{password: password}))

    {:reply, return, %{state | waiting_for_frame: :GW_PASSWORD_ENTER_CFM}}
  end

  @impl GenServer
  def handle_call(:nodes, _from, state) do
    {:reply, state.nodes, state}
  end

  @impl GenServer
  def handle_call(
        {:command, cmd, data},
        from,
        %{next_session: session, logged_in: logged_in} = state
      ) do
    if logged_in do
      data_params = Map.put(data, :session, session)
      :ok = Socket.Stream.send(state.socket, Api.request(cmd, data_params))
      {:noreply, %{state | next_session: update_session(session), waiting_client: from}}
    else
      {:reply, {:error, :not_logged_in}, state}
    end
  end

  @impl GenServer
  def handle_cast({:recv, data}, state) do
    response = Api.response(data) |> IO.inspect(label: "recv data")

    new_state =
      case response do
        {:ok, resp_data} ->
          if state.waiting_client, do: GenServer.reply(state.waiting_client, resp_data)
          update_state(state, resp_data)

        {:error, reason} ->
          if state.waiting_client, do: GenServer.reply(state.waiting_client, {:error, reason})
          state
      end

    {:noreply, new_state}
  end

  defp listen(socket) do
    case Socket.Stream.recv!(socket) do
      data -> GenServer.cast(__MODULE__, {:recv, data})
    end

    listen(socket)
  end

  defp update_session(session) do
    case session do
      65_535 -> 0
      _ -> session + 1
    end
  end

  defp update_state(%{waiting_for_frame: :GW_PASSWORD_ENTER_CFM} = state, %{
         frame: :GW_PASSWORD_ENTER_CFM,
         payload: payload
       }) do
    %{state | waiting_for_frame: nil, logged_in: payload}
  end

  defp update_state(state, %{frame: :GW_GET_ALL_NODES_INFORMATION_NTF, payload: node}) do
    %{state | nodes: Map.put(state.nodes, node.node, node)}
  end

  defp update_state(state, %{frame: _frame, payload: _payload}), do: state
end
