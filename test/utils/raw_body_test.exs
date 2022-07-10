defmodule ExSlack.Utils.CacheBodyReaderTest do
  use ExUnit.Case, async: true
  use Plug.Test

  # These are not really what's intended, pending feedback on
  # https://github.com/elixir-plug/plug/pull/1110
  test "saves raw_body value" do
    assert {:ok, "", conn} =
             conn(:get, "/test", %{
               "hello" => "world"
             })
             |> ExSlack.Utils.CacheBodyReader.read_body()

    assert conn.assigns.raw_body == [""]

    assert {:ok, "--plug_conn_test--", conn} =
             conn(:post, "/test", %{
               "hello" => "world"
             })
             |> ExSlack.Utils.CacheBodyReader.read_body()

    assert conn.assigns.raw_body == ["--plug_conn_test--"]
  end
end
