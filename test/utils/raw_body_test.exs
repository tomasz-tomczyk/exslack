defmodule ExSlack.Utils.CacheBodyReaderTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "saves raw_body value" do
    assert {:ok, _body, conn} =
             conn(:get, "/test", "{\"hello\":\"world\"")
             |> ExSlack.Utils.CacheBodyReader.read_body()

    assert conn.assigns.raw_body == ["{\"hello\":\"world\""]

    assert {:ok, _body, conn} =
             conn(:post, "/test", "{\"hello\":\"world\"")
             |> ExSlack.Utils.CacheBodyReader.read_body()

    assert conn.assigns.raw_body == ["{\"hello\":\"world\""]
  end
end
