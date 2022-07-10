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
  @spec init(keyword()) :: keyword()
  def init(options), do: Keyword.put_new(options, :request_path, "/__slack_url_verification")

  @impl true
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(
        %{
          request_path: request_path,
          params: %{"challenge" => challenge, "token" => _token, "type" => "url_verification"}
        } = conn,
        opts
      ) do
    with {:ok, timestamp} <- get_timestamp(conn),
         {:ok, _continue} <- is_valid_path?(request_path, opts),
         {:ok, _continue} <- is_replay_attack?(timestamp, opts),
         {:ok, _continue} <- is_valid_signature?(conn, opts, timestamp) do
      conn
      |> resp(200, challenge)
      |> halt()
    else
      {:skip, :invalid_path} ->
        conn

      _errors ->
        conn
        |> resp(500, "")
        |> halt()
    end
  end

  defp is_valid_signature?(conn, opts, timestamp) do
    slack_signature = Plug.Conn.get_req_header(conn, "x-slack-signature") |> List.first()
    raw_body = conn.assigns.raw_body |> List.first()
    sig_basestring = "v0:#{timestamp}:" <> raw_body
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
    current_time =
      opts
      |> Keyword.get(:now, DateTime.utc_now())
      |> DateTime.to_unix()

    if abs(current_time - timestamp) < @allowed_time_discrepency do
      {:ok, :continue}
    else
      {:error, :replay_attack}
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
    conn
    |> Plug.Conn.get_req_header("x-slack-request-timestamp")
    |> List.first()
    |> Integer.parse()
    |> case do
      {timestamp, ""} -> {:ok, timestamp}
      :error -> {:error, :invalid_timestamp}
    end
  end
end
