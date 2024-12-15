defmodule Klf200.Api.Confirmations do
  require Logger

  @cfm %{
    # "0000" => :GW_ERROR_NTF,
    # "0002" => :GW_REBOOT_CFM,
    "0009" => :GW_GET_VERSION_CFM,
    "000B" => :GW_GET_PROTOCOL_VERSION_CFM,
    "0203" => :GW_GET_ALL_NODES_INFORMATION_CFM,
    "0204" => :GW_GET_ALL_NODES_INFORMATION_NTF,
    "0205" => :GW_GET_ALL_NODES_INFORMATION_FINISHED_NTF,
    "0301" => :GW_COMMAND_SEND_CFM,
    "0302" => :GW_COMMAND_RUN_STATUS_NTF,
    "0303" => :GW_COMMAND_REMAINING_TIME_NTF,
    "0304" => :GW_SESSION_FINISHED_NTF,
    "0306" => :GW_STATUS_REQUEST_CFM,
    # "0307" => :GW_STATUS_REQUEST_NTF,
    # "0321" => :GW_MODE_SEND_CFM,
    # "0322" => :GW_MODE_SEND_NTF,
    "3001" => :GW_PASSWORD_ENTER_CFM
  }

  @status_ids %{
    1 => :user,
    2 => :rain,
    3 => :timer,
    5 => :ups,
    8 => :program,
    9 => :wind,
    10 => :actuator,
    11 => :auto_cycle,
    12 => :emergency,
    16 => :unknown
  }

  @status_replies %{
    0 => :unknown,
    1 => :ok,
    2 => :no_contact,
    3 => :manual_operation,
    4 => :blocked,
    5 => :wrong_system_key,
    6 => :priority_level_locked,
    7 => :reached_wrong_position,
    8 => :error,
    9 => :no_exec,
    10 => :calibrating,
    11 => :power_consumption_too_high,
    12 => :power_consumption_too_low
    # ....
  }

  @node_types %{
    64 => :interior_venetian_blind,
    128 => :roller_shutter,
    129 => :roller_shutter_adjustable,
    130 => :roller_shutter_with_projection,
    192 => :vertical_exterior_awning,
    256 => :window_opener,
    257 => :window_opener_with_rain_sensor
    # ...
  }

  @states %{
    0 => :non_exec,
    1 => :error,
    3 => :waiting_for_power,
    4 => :executing,
    5 => :done,
    255 => :unknown
  }

  @velocity %{
    0 => :default,
    1 => :silent,
    2 => :fast,
    255 => :not_available
  }

  @node_variations %{
    0 => :not_set,
    1 => :top_hung,
    2 => :kip,
    3 => :flat_roof,
    4 => :sky_light
  }

  @alias_names %{
    "D803" => :secured_ventilation
  }

  def parse(cfm, data) do
    frame = Map.get(@cfm, Base.encode16(cfm), cfm)

    do_parse(frame, data)
    |> case do
      {:error, :not_implemented} -> %{frame: frame, payload: data}
      payload -> %{frame: frame, payload: payload}
    end
  end

  defp do_parse(
         :GW_GET_VERSION_CFM,
         <<software::binary-size(6), hardware::binary-size(1), _rest::binary>>
       ) do
    %{software: software, hardware: hardware}
  end

  defp do_parse(:GW_GET_PROTOCOL_VERSION_CFM, <<major::16, minor::16>>) do
    %{major: major, minor: minor}
  end

  defp do_parse(:GW_GET_ALL_NODES_INFORMATION_CFM, <<status::8, count::8>>) do
    %{
      status:
        case status do
          0 -> :ok
          1 -> :no_nodes
        end,
      node_count: count
    }
  end

  defp do_parse(
         :GW_GET_ALL_NODES_INFORMATION_NTF,
         <<node::8, order::16, placement::8, name::binary-size(64), velocity::8, node_type::16, product_group::8,
           product_type::8, node_variation::8, power_mode::8, build_number::8, serial_number::64, state::8,
           current_pos::16, target::16, fp1_current_pos::16, fp2_current_pos::16, fp3_current_pos::16,
           fp4_current_pos::16, remaining_time::16, timestamp::32, number_of_aliases::8, alias_array::binary>>
       ) do
    %{
      node: node,
      order: order,
      placement: placement,
      name: String.trim(name, <<0>>),
      velocity: Map.get(@velocity, velocity, velocity),
      node_type: Map.get(@node_types, node_type, node_type),
      product_group: product_group,
      product_type: product_type,
      node_variation: Map.get(@node_variations, node_variation, node_variation),
      power_mode:
        case power_mode do
          0 -> :always_alive
          1 -> :low_power_mode
        end,
      build_number: build_number,
      serial_number: serial_number,
      state: Map.get(@states, state, state),
      current_pos: current_pos,
      target: target,
      fp1_current_pos: fp1_current_pos,
      fp2_current_pos: fp2_current_pos,
      fp3_current_pos: fp3_current_pos,
      fp4_current_pos: fp4_current_pos,
      remaining_time: remaining_time,
      timestamp: timestamp,
      number_of_aliases: number_of_aliases,
      aliases: aliases(alias_array)
    }
  end

  defp do_parse(:GW_GET_ALL_NODES_INFORMATION_FINISHED_NTF, _) do
    :node_information_finished
  end

  defp do_parse(:GW_COMMAND_SEND_CFM, <<session::16, status::8>>) do
    %{session: session, status: status}
  end

  defp do_parse(
         :GW_COMMAND_RUN_STATUS_NTF,
         # Identification of the status owner
         <<session::16, status_id::8, index::8, node_parameter::8, value::16, status::8, status_reply::8,
           information::binary>>
       ) do
    %{
      session: session,
      triggered_by: Map.get(@status_ids, status_id, status_id),
      index: index,
      parameter: parameter(node_parameter),
      value: value,
      status:
        case status do
          0 -> :ok
          1 -> :error
          2 -> :still_active
        end,
      reply: Map.get(@status_replies, status_reply, status_reply),
      information: information
    }
  end

  defp do_parse(
         :GW_COMMAND_REMAINING_TIME_NTF,
         <<session::16, node::8, node_parameter::8, seconds::16>>
       ) do
    %{session: session, node: node, parameter: parameter(node_parameter), seconds: seconds}
  end

  defp do_parse(:GW_SESSION_FINISHED_NTF, <<session::16>>) do
    %{session: session}
  end

  defp do_parse(:GW_STATUS_REQUEST_CFM, <<_session::16, status::8>>) do
    case status do
      0 -> :ok
      1 -> :error
    end
  end

  defp do_parse(:GW_PASSWORD_ENTER_CFM, <<status::8>>) do
    case status do
      0 -> :ok
      1 -> :error
    end
  end

  defp do_parse(cfm, data) do
    Logger.warning("[klf200] unsupported cfm #{inspect(cfm)} with data: #{inspect(data)}")
    {:error, :not_implemented}
  end

  defp parameter(0), do: :main
  defp parameter(n), do: :"fp#{n}"

  defp aliases(<<data::binary>>), do: aliases(data, [])

  defp aliases(<<type::16, value::16, rest::binary>>, aliases) when type > 0 do
    id = Integer.to_string(type, 16)
    aliases(rest, aliases ++ [%{id: id, name: Map.get(@alias_names, id, id), value: value}])
  end

  defp aliases(<<_data::binary>>, aliases), do: aliases
end
