defmodule Klf200.Api.Requests do
  @commands %{
    # GW_REBOOT_REQ: "0001",
    GW_GET_VERSION_REQ: "0008",
    GW_GET_PROTOCOL_VERSION_REQ: "000A",
    GW_GET_ALL_NODES_INFORMATION_REQ: "0202",
    GW_COMMAND_SEND_REQ: "0300",
    GW_STATUS_REQUEST_REQ: "0305",
    # GW_MODE_SEND_REQ: "0320",
    GW_PASSWORD_ENTER_REQ: "3000"
    # GW_GET_STATE_REQ
  }

  @status_types %{
    target_position: <<0>>,
    current_position: <<1>>,
    remaining_time: <<2>>,
    main_info: <<3>>
  }

  # Stand Alone Automatic Controls
  @command_originator_saac <<8>>
  # Used by Stand Alone Automatic Controls
  @priority_level <<5>>
  @parameter_active <<0>>

  @spec build(cmd :: atom(), data :: map()) :: binary()
  def build(cmd, data) do
    command_binary =
      case Map.get(@commands, cmd) do
        nil -> Base.decode16!(cmd)
        cmd_string -> Base.decode16!(cmd_string)
      end

    command_frame =
      case build_data(cmd, data) do
        nil -> command_binary
        data_binary -> command_binary <> data_binary
      end

    <<byte_size(command_frame) + 1::integer-size(8)>> <> command_frame
  end

  defp build_data(:GW_GET_VERSION_REQ, _data), do: nil

  defp build_data(:GW_GET_PROTOCOL_VERSION_REQ, _data), do: nil

  defp build_data(:GW_GET_ALL_NODES_INFORMATION_REQ, _data), do: nil

  defp build_data(:GW_COMMAND_SEND_REQ, %{session: session, node: node, stop: true}),
    do:
      build_data(:GW_COMMAND_SEND_REQ, %{
        session: session,
        node: node,
        position: Base.decode16!("D200")
      })

  defp build_data(:GW_COMMAND_SEND_REQ, %{session: session, node: node, position: position}) do
    priority_level_lock = <<0>>
    fpi1 = <<0>>
    fpi2 = <<0>>

    # 0x000 -> open / 0xC800 -> closed
    pos = position * 512
    # 17x 16bit integer -> 34 bytes long
    # first 16bit are MP param and then 16 params for every additional functional parameter
    functional_parameter_value = <<pos::16>> <> <<0::256>>
    # 'IndexArrayCount' must be a number from 1 to 20, both included
    index_array_count = <<1>>
    # 'IndexArray' is always 20 bytes long, even if 'IndexArrayCount' parameter is below 20.
    index_array = <<node::8>> <> <<0::152>>
    pli_0_3 = <<0>>
    pli_4_7 = <<0>>
    lock_time = <<0>>

    <<session::16>> <>
      @command_originator_saac <>
      @priority_level <>
      @parameter_active <>
      fpi1 <>
      fpi2 <>
      functional_parameter_value <>
      index_array_count <>
      index_array <>
      priority_level_lock <>
      pli_0_3 <>
      pli_4_7 <>
      lock_time
  end

  defp build_data(:GW_STATUS_REQUEST_REQ, %{session: session, status_type: status_type}) do
    index_array_count = <<1>>
    index_array = <<0::160>>
    fpi1 = <<0>>
    fpi2 = <<0>>

    <<session::16>> <>
      index_array_count <> index_array <> @status_types[status_type] <> fpi1 <> fpi2
  end

  defp build_data(:GW_PASSWORD_ENTER_REQ, %{password: password}) do
    # The password parameter must contain a paraphrase followed by zeros. Last byte of Password byte array must be null terminated
    String.pad_trailing(password, 31, <<0>>) <> <<0>>
  end

  defp build_data(cmd, data) when is_atom(cmd) do
    IO.puts("unsupported cmd #{inspect(cmd)} with data: #{inspect(data)}")
    {:error, :not_implemented}
  end

  defp build_data(_cmd, _data), do: nil
end
