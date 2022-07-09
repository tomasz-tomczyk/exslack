defmodule ExSlack.Utils.EventsPlug do
  import Plug.Conn
  require Logger
  @behaviour Plug

  @moduledoc """
  Implements URL verification for Slack

  Based on docs: https://api.slack.com/authentication/verifying-requests-from-slack

  ## Usage

  Add it to your endpoint.ex as such:

    plug ExSlack.EventsPlug,
      slack_signing_secret: "6215a3d6eb3ccf9100d1bfaa8956364f"

  ## Options

    * `:slack_signing_secret` - obtained from Slack

    * `:request_path` - URL to be used for verification. Defaults to
      `/__slack_url_verification`

    * `:now` - DateTime to be used for verification, used only for tests
  """

  @allowed_time_discrepency 60 * 5

  @impl true
  def init(options), do: Keyword.put_new(options, :request_path, "/__slack_url_verification")

  @impl true
  def call(
        %{
          request_path: request_path,
          params: %{"challenge" => challenge, "token" => _token, "type" => "url_verification"}
        } = conn,
        opts
      ) do
    with {:ok, _} <- is_valid_path?(request_path, opts),
         timestamp <- get_timestamp(conn),
         {:ok, _} <- is_replay_attack?(timestamp, opts),
         {:ok, _} <- compare_signatures(conn, opts, timestamp) do
      conn
      |> resp(200, challenge)
      |> halt()
    else
      {:skip, :invalid_path} ->
        conn

      {:skip, :replay_attack} ->
        conn
        |> resp(500, "")
        |> halt()

      {:error, :invalid_signature} ->
        conn
        |> resp(500, "")
        |> halt()

      true ->
        conn
    end
  end

  defp compare_signatures(conn, opts, timestamp) do
    slack_signature = Plug.Conn.get_req_header(conn, "x-slack-signature") |> List.first()
    request_body = conn.assigns.raw_body |> List.first()
    sig_basestring = "v0:#{timestamp}:" <> request_body
    slack_signing_secret = Keyword.fetch!(opts, :slack_signing_secret)

    my_signature =
      "v0=" <>
        (:crypto.mac(:hmac, :sha256, slack_signing_secret, sig_basestring)
         |> Base.encode16()
         |> String.downcase())

    if Plug.Crypto.secure_compare(my_signature, slack_signature) do
      {:ok, :continue}
    else
      {:error, :invalid_signature}
    end
  end

  defp is_replay_attack?(timestamp, opts) do
    current_time = get_current_time(opts)

    if abs(current_time - timestamp) < @allowed_time_discrepency do
      {:ok, :continue}
    else
      {:skip, :replay_attack}
    end
  end

  defp is_valid_path?(request_path, opts) do
    if request_path == Keyword.fetch!(opts, :request_path) do
      {:ok, :continue}
    else
      {:skip, :invalid_path}
    end
  end

  defp get_timestamp(conn) do
    timestamp_s = Plug.Conn.get_req_header(conn, "x-slack-request-timestamp") |> List.first()
    {timestamp, ""} = Integer.parse(timestamp_s)

    timestamp
  end

  defp get_current_time(opts) do
    Keyword.get(opts, :now, DateTime.utc_now())
    |> DateTime.to_unix()
  end
end
