defmodule ExSlack.Utils.RawBody do
  @moduledoc """
  Saves raw body of the request. Required for Slack URL verification.
  """
  def cache_raw_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end
