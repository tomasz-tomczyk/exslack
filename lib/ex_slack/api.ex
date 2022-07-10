defmodule ExSlack.API do
  @moduledoc """
  Tesla Wrapper around Slack's Web API.
  """
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://slack.com/api")
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.BearerAuth, token: get_access_token())
  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.FormUrlencoded)

  @doc """
  Internal wrapper around Tesla's response, returning the contents.
  """
  @spec handle_response(Tesla.Env.result()) :: any
  def handle_response({:ok, %{body: %{"error" => error}}}), do: {:error, error}
  def handle_response({:ok, response}), do: {:ok, response.body}

  defp get_access_token do
    Application.fetch_env!(:exslack, :access_token)
  end
end
