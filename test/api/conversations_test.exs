defmodule ExSlack.API.ConversationsTest do
  use ExUnit.Case, async: true
  alias ExSlack.API.Conversations

  setup do
    Tesla.Mock.mock(fn
      %{
        method: :get,
        url: "https://slack.com/api/conversations.history",
        query: %{channel: "invalid_channel"}
      } ->
        %Tesla.Env{
          body: %{"error" => "channel_not_found", "ok" => false},
          status: 200
        }

      %{method: :get, url: "https://slack.com/api/conversations.history"} ->
        %Tesla.Env{
          body: %{
            "latest" => "1657478960.263519",
            "messages" => [
              %{
                "text" => "Test",
                "ts" => "1657478960.263519"
              }
            ]
          },
          status: 200
        }
    end)

    :ok
  end

  test "get conversation" do
    assert {:ok, response} = Conversations.history("1", "1657478960.263519")

    assert response == %{
             "latest" => "1657478960.263519",
             "messages" => [%{"text" => "Test", "ts" => "1657478960.263519"}]
           }

    assert {:error, "channel_not_found"} =
             Conversations.history("invalid_channel", "1657478960.263519")
  end
end
