defmodule ExSlack.API.ViewsTest do
  use ExUnit.Case, async: true
  alias ExSlack.API.Views

  setup do
    Tesla.Mock.mock(fn
      %{
        method: :post,
        url: "https://slack.com/api/views.open",
        body: "{\"trigger_id\":\"expired.trigger\",\"view\":{}}"
      } ->
        %Tesla.Env{
          body: %{"error" => "expired_trigger_id", "ok" => false},
          status: 200
        }

      %{
        method: :post,
        url: "https://slack.com/api/views.open",
        body:
          "{\"trigger_id\":\"valid.trigger\",\"view\":{\"blocks\":[{\"element\":{\"action_id\":\"field\",\"multiline\":true,\"placeholder\":{\"text\":\"Input field\",\"type\":\"plain_text\"},\"type\":\"plain_text_input\"},\"label\":{\"emoji\":true,\"text\":\"Input field\",\"type\":\"plain_text\"},\"type\":\"input\"}],\"submit\":{\"text\":\"Submit\",\"type\":\"plain_text\"},\"title\":{\"text\":\"Title\",\"type\":\"plain_text\"},\"type\":\"modal\"}}"
      } ->
        %Tesla.Env{
          body: %{"error" => "expired_trigger_id", "ok" => false},
          status: 200
        }
    end)

    :ok
  end

  test "open view" do
    view = %{
      "title" => %{
        "type" => "plain_text",
        "text" => "Title"
      },
      "submit" => %{
        "type" => "plain_text",
        "text" => "Submit"
      },
      "blocks" => [
        %{
          "type" => "input",
          "element" => %{
            "type" => "plain_text_input",
            "multiline" => true,
            "action_id" => "field",
            "placeholder" => %{
              "type" => "plain_text",
              "text" => "Input field"
            }
          },
          "label" => %{
            "type" => "plain_text",
            "text" => "Input field",
            "emoji" => true
          }
        }
      ],
      "type" => "modal"
    }

    assert {:error, "expired_trigger_id"} = Views.open("expired.trigger", %{})
    assert {:error, "expired_trigger_id"} = Views.open("valid.trigger", view)
  end
end
