defmodule ExSlack.Utils.CacheBodyReader do
  @moduledoc """
  Saves raw body of the request. Required for Slack URL verification.

  See https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader

  # Usage

  Add it to your endpoint.ex in Plug.Parsers configuration:

    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      body_reader: {ExSlack.Utils.CacheBodyReader, :read_body, []},
      json_decoder: Phoenix.json_library()

  Ensure this is done before your app's router for it to be accessible to
  `ExSlack.Utils.VerifyPlug`

  """

  @doc """
  Saves the request body in conn.assigns[:raw_body].

  To be used as a body reader in Plug.Parsers.
  """
  @spec read_body(Plug.Conn.t(), keyword()) :: {:ok, binary, Plug.Conn.t()}
  def read_body(conn, opts \\ []) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end
