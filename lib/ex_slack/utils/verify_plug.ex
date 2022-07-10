defmodule ExSlack.Utils.VerifyPlug do
  @moduledoc """
  Implements URL verification for Slack

  Based on docs: https://api.slack.com/authentication/verifying-requests-from-slack

  Assumes request's raw body to be present in `conn.assigns.raw_body` - see
  `ExSlack.Utils.RawBody` for a parser that will cache it.

  ## Usage

  Create a pipeline using the plug in your router:

    pipeline :slack do
      plug ExSlack.Utils.VerifyPlug,
        slack_signing_secret: "6215a3d6eb3ccf9100d1bfaa8956364f"
    end

  Create a scope that uses the pipeline:

    scope "/bot", MyAppWeb do
      pipe_through :slack

      post "/event", EventController, :parse
    end

  You can use any route piped through this pipeline as the destination for your
  events from Slack. When provided a "challenge" param from Slack, it will
  respond with the value assuming the other verification passes.

  ## Options

    * `:slack_signing_secret` - obtained from Slack

    * `:now` - DateTime to be used for verification, used only for tests
  """
  import Plug.Conn
  require Logger
  @behaviour Plug

  @allowed_time_discrepency 60 * 5

  @impl true
  @spec init(keyword()) :: keyword()
  def init(options), do: options

  @impl true
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    with {:ok, timestamp} <- get_timestamp(conn),
         {:ok, _continue} <- is_replay_attack?(timestamp, opts),
         {:ok, _continue} <- is_valid_signature?(conn, opts, timestamp) do
      if Map.get(conn.params, "type") == "url_verification" do
        conn
        |> send_resp(200, Map.get(conn.params, "challenge"))
        |> halt()
      else
        conn
      end
    else
      _errors ->
        conn
        |> send_resp(500, "")
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
