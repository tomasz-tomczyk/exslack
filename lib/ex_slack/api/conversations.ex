defmodule ExSlack.API.Conversations do
  @moduledoc """
  Web API functions for Conversations
  """

  @doc """
  Retrieves a single message.

  ## Examples

    iex> ExSlack.API.Conversations.history("C03CY75AH0C", "1657478960.263519")
    {:ok,
    %{
      "channel_actions_count" => 0,
      "channel_actions_ts" => nil,
      "has_more" => true,
      "latest" => "1657478960.263519",
      "messages" => [
        %{
          "blocks" => [
            %{
              "block_id" => "0qZgf",
              "elements" => [
                %{
                  "elements" => [%{"text" => "Test", "type" => "text"}],
                  "type" => "rich_text_section"
                }
              ],
              "type" => "rich_text"
            }
          ],
          "client_msg_id" => "a46aa00a-71a0-4d81-a5c2-6fd688ae7341",
          "team" => "T03CY759SN8",
          "text" => "Test",
          "ts" => "1657478960.263519",
          "type" => "message",
          "user" => "U03CF8WE5RV"
        }
      ],
      "ok" => true,
      "pin_count" => 0,
      "response_metadata" => %{"next_cursor" => "bmV4dF90czoxNjU3NDcxNzQ1NzA0NjA5"}
    }}
  """
  @spec history(String.t(), String.t()) :: {:error, any} | {:ok, map()}
  def history(conversation_id, ts) do
    ExSlack.API.get(
      "/conversations.history",
      query: %{channel: conversation_id, latest: ts, limit: 1, inclusive: true}
    )
    |> ExSlack.API.handle_response()
  end
end
