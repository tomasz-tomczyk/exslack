defmodule ExSlack.API.Views do
  @moduledoc """
  Web API functions for Views
  """

  @doc """
  Opens a view.

  ## Examples

    iex> view = %{
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
    iex> ExSlack.API.Views.open("3777835113989.3440243332756.e76e2cb27d6f7ed28eab0dfe3abebd6a", view)

  """
  @spec open(String.t(), map()) :: {:error, any} | {:ok, map()}
  def open(trigger_id, view) do
    ExSlack.API.post("/views.open", %{trigger_id: trigger_id, view: view})
    |> ExSlack.API.handle_response()
  end
end
