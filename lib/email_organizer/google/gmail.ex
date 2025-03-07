defmodule EmailOrganizer.Google.Gmail do
  @moduledoc """
  A module for interacting with Gmail.
  """

  alias EmailOrganizer.Utils
  alias GoogleApi.Gmail.V1
  alias GoogleApi.Gmail.V1.Api
  alias GoogleApi.Gmail.V1.Model.WatchRequest

  @type subscribe_response :: %{
          history_id: integer(),
          expires_at: DateTime.t()
        }

  @project_id Application.compile_env(:email_organizer, :pub_sub_project_id)
  @topic Application.compile_env(:email_organizer, :pub_sub_topic)

  @spec subscribe_user_emails(String.t()) :: {:ok, subscribe_response()} | {:error, any()}
  def subscribe_user_emails(auth_token) do
    connection = V1.Connection.new(auth_token)
    watch_request = %WatchRequest{topicName: get_topic_name()}

    with {:ok, response} <- Api.Users.gmail_users_watch(connection, "me", body: watch_request) do
      {:ok,
       %{
         history_id: response.historyId,
         expires_at:
           response.expiration |> String.to_integer() |> DateTime.from_unix!(:millisecond)
       }}
    end
  end

  defp get_topic_name do
    "projects/#{Utils.get_config_value(@project_id)}/topics/#{Utils.get_config_value(@topic)}"
  end
end
