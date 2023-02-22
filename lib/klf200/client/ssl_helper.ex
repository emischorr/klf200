defmodule Klf200.Client.SSL_Helper do
  @moduledoc """
  See: https://mw.gl/posts/elixir_ssl/
  """

  def verify_fun(_, {:extension, _}, state) do
    {:unknown, state}
  end

  def verify_fun(cert, _, state) do
    case state do
      {:sha, match} ->
        verify_cert_fingerprint(cert, match)

      _ ->
        {:fail, :fingerprint_no_match}
    end
  end

  def verify_cert_fingerprint(cert, match) do
    cert_binary = :public_key.pkix_encode(:OTPCertificate, cert, :otp)
    hash = :crypto.hash(:sha, cert_binary) |> Base.encode16()

    case hash == match do
      true -> {:valid, hash}
      false -> {:fail, :fingerprint_no_match}
    end
  end
end
