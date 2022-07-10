defmodule ExSlack.Utils.EventsPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Plug.Conn
  alias ExSlack.Utils.EventsPlug

  # Wasn't too sure how to mock all of these values, so this was a real request.
  # Regenerated the secret since then.
  @slack_signing_secret "6215a3d6eb3ccf9100d1bfaa8956364f"

  setup do
    conn =
      :get
      |> conn("/__slack_url_verification", %{
        "challenge" => "PzW6yEqcajalgLQ4TiLrv28MnMa4QFWR5kJKsH9rCkrwlkpeKFE4",
        "token" => "YMyckcTNASDyJ6xUnXmaDJlU",
        "type" => "url_verification"
      })
      |> put_req_header("x-slack-request-timestamp", "1657377984")
      |> put_req_header(
        "x-slack-signature",
        "v0=8bcf11adb4458c4bd341d33bbe34514b3c5e3cf5da86503033ae4b2cdc53db85"
      )
      |> assign(:raw_body, [
        "{\"token\":\"YMyckcTNASDyJ6xUnXmaDJlU\",\"challenge\":\"PzW6yEqcajalgLQ4TiLrv28MnMa4QFWR5kJKsH9rCkrwlkpeKFE4\",\"type\":\"url_verification\"}"
      ])

    {:ok, conn: conn}
  end

  test "returns valid challenge value when provided the correct secret", %{conn: conn} do
    options =
      EventsPlug.init(
        slack_signing_secret: @slack_signing_secret,
        now: ~U[2022-07-09 14:46:24.390519Z]
      )

    conn = conn |> EventsPlug.call(options)
    assert {:ok, "", %{status: 200, resp_body: resp_body} = _conn} = read_body(conn)
    assert resp_body == "PzW6yEqcajalgLQ4TiLrv28MnMa4QFWR5kJKsH9rCkrwlkpeKFE4"
  end

  test "returns 500 when suspecting of replay attack", %{conn: conn} do
    options =
      EventsPlug.init(
        slack_signing_secret: @slack_signing_secret,
        now: ~U[2022-08-09 14:46:24.390519Z]
      )

    conn = conn |> EventsPlug.call(options)
    assert {:ok, "", %{status: 500, resp_body: ""} = _conn} = read_body(conn)
  end

  test "returns 500 when signatures don't match as a result of invalid secret", %{conn: conn} do
    options =
      EventsPlug.init(
        slack_signing_secret: "invalid-secret",
        now: ~U[2022-07-09 14:46:24.390519Z]
      )

    conn = conn |> EventsPlug.call(options)
    assert {:ok, "", %{status: 500, resp_body: ""} = _conn} = read_body(conn)
  end

  test "returns conn when the url doesn't match", %{conn: conn} do
    options =
      EventsPlug.init(
        slack_signing_secret: @slack_signing_secret,
        now: ~U[2022-07-09 14:46:24.390519Z],
        request_path: "/slack-url-verification"
      )

    conn = conn |> EventsPlug.call(options)
    assert {:ok, "", %{status: nil, resp_body: nil} = _conn} = read_body(conn)
  end

  test "returns error when slack signing secret isn't present", %{conn: conn} do
    options = EventsPlug.init(now: ~U[2022-07-09 14:46:24.390519Z])

    assert_raise KeyError, fn ->
      conn |> EventsPlug.call(options)
    end
  end
end
