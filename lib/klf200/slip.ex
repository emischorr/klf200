defmodule Klf200.Slip do
  @moduledoc """
  SLIP stands for the Serial Line Internet Protocol which is a basic encapsulation mechanism for IP packets.
  It's documented in RFC 1055.

  This module provides just two public functions to pack and unpack a frame.
  """

  # SLIP escape characters as per RFC 1055
  @slip_end Base.decode16!("C0")
  @slip_esc Base.decode16!("DB")
  @slip_esc_end Base.decode16!("DC")
  @slip_esc_esc Base.decode16!("DD")

  @spec pack(bitstring) :: <<_::16, _::_*8>>
  def pack(frame) do
    @slip_end <> escape(frame) <> @slip_end
  end

  @spec unpack(any) :: bitstring | {:error, :missing_slip_end}
  def unpack(<<@slip_end, rest::binary>>) do
    frame_size = byte_size(rest) - 1
    <<frame::binary-size(frame_size), @slip_end>> = rest
    unescape(frame)
  end

  def unpack(_), do: {:error, :missing_slip_end}

  # private

  defp escape(<<byte::binary-size(1), rest::binary>>),
    do: escape(rest, escape_byte(byte))

  defp escape(<<byte::binary-size(1), rest::binary>>, escaped_bytes),
    do: escape(rest, escaped_bytes <> escape_byte(byte))

  defp escape(_, escaped_bytes), do: escaped_bytes

  defp escape_byte(@slip_end), do: @slip_esc <> @slip_esc_end
  defp escape_byte(@slip_esc), do: @slip_esc <> @slip_esc_esc
  defp escape_byte(byte), do: byte

  defp unescape(<<@slip_esc, byte::binary-size(1), rest::binary>>),
    do: unescape(rest, unescape_byte(byte))

  defp unescape(<<byte::binary-size(1), rest::binary>>),
    do: unescape(rest, unescape_byte(byte))

  defp unescape(<<byte::binary-size(1), rest::binary>>, unescaped_bytes),
    do: unescape(rest, unescaped_bytes <> unescape_byte(byte))

  defp unescape(_, unescaped_bytes), do: unescaped_bytes

  defp unescape_byte(@slip_esc_end), do: @slip_end
  defp unescape_byte(@slip_esc_esc), do: @slip_esc
  defp unescape_byte(byte), do: byte
end
