defmodule EmailOrganizer.Google.Gmail do
  @moduledoc """
  A module for interacting with Gmail.
  """

  alias GoogleApi.Gmail.V1
  alias GoogleApi.Gmail.V1.Api

  @type subscribe_response :: %{
          history_id: integer(),
          expires_at: DateTime.t()
        }

  @spec subscribe_user_emails(String.t()) :: {:ok, subscribe_response()} | {:error, any()}
  def subscribe_user_emails(auth_token) do
    connection = V1.Connection.new(auth_token)

    with {:ok, response} <- Api.Users.gmail_users_watch(connection, "me") do
      {:ok,
       %{
         history_id: response.historyId,
         expires_at:
           response.expiration |> String.to_integer() |> DateTime.from_unix!(:millisecond)
       }}
    end
  end
end
