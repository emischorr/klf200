defmodule Klf200.Api do
  @moduledoc """
  This module provides functions on a general API level to create requests and to parse responses.
  It implements the basic protocol described by VELUX.

  The actual commands and confirmations are defined in sub-modules.
  """

  alias Klf200.Slip
  alias Klf200.Api.{Requests, Confirmations}

  @protocol_id <<0::8>>

  @spec request(atom) :: <<_::16, _::_*8>>
  def request(cmd), do: request(cmd, %{})

  @spec request(atom, map) :: <<_::16, _::_*8>>
  def request(cmd, data) do
    cmd |> build_command(data) |> build_message() |> Slip.pack()
  end

  @spec response(bitstring) ::
          {:error, :protocol_mismatch | :wrong_checksum} | {:ok, %{frame: atom(), payload: any}}
  def response(frame) do
    frame
    |> Slip.unpack()
    |> parse_message()
    |> case do
      {:ok, payload} -> {:ok, parse_command(payload)}
      {:error, reason} -> {:error, reason}
    end
  end

  # private

  defp build_message(command_frame) do
    message = @protocol_id <> command_frame
    message <> checksum(message)
  end

  defp parse_message({:error, error}), do: {:error, error}

  defp parse_message(message) do
    payload_size = byte_size(message) - 2
    <<protocol::binary-size(1), payload::binary-size(payload_size), cs::binary-size(1)>> = message

    cond do
      protocol != @protocol_id -> {:error, :protocol_mismatch}
      cs != checksum(protocol <> payload) -> {:error, :wrong_checksum}
      true -> {:ok, payload}
    end
  end

  @spec build_command(atom() | bitstring(), map()) :: nonempty_binary()
  defp build_command(command, data) do
    Requests.build(command, data)
  end

  defp parse_command(<<_length::binary-size(1), command::binary-size(2), data::binary>>) do
    Confirmations.parse(command, data)
  end

  defp checksum(<<byte::8, rest::binary>>), do: checksum(rest, <<byte>>)

  defp checksum(<<byte::8, rest::binary>>, sum) do
    checksum(rest, :crypto.exor(sum, <<byte>>))
  end

  defp checksum(_, sum), do: sum
end
