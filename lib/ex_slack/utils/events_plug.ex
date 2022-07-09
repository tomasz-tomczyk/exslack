defmodule ExSlack.Utils.EventsPlug do
  import Plug.Conn
  require Logger
  @behaviour Plug

  @moduledoc """
  Implements URL verification for Slack

  Based on docs: https://api.slack.com/events/url_verification

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
    if request_path == Keyword.get(opts, :request_path) do
      slack_signing_secret = Keyword.get(opts, :slack_signing_secret)
      request_body = conn.assigns.raw_body |> List.first()

      timestamp_string =
        Plug.Conn.get_req_header(conn, "x-slack-request-timestamp") |> List.first()

      {timestamp, ""} = Integer.parse(timestamp_string)

      now =
        Keyword.get(opts, :now, DateTime.utc_now())
        |> DateTime.to_unix()

      if abs(now - timestamp) > 60 * 5 do
        Logger.warn("[ExSlack] Potential replay attack")

        conn
        |> resp(500, "")
      else
        slack_signature = Plug.Conn.get_req_header(conn, "x-slack-signature") |> List.first()

        sig_basestring = "v0:" <> timestamp_string <> ":" <> request_body

        my_signature =
          "v0=" <>
            (:crypto.mac(:hmac, :sha256, slack_signing_secret, sig_basestring)
             |> Base.encode16()
             |> String.downcase())

        if Plug.Crypto.secure_compare(my_signature, slack_signature) do
          conn
          |> resp(200, challenge)
          |> halt()
        else
          conn
          |> resp(500, "")
          |> halt()
        end
      end
    else
      conn
    end
  end
end
