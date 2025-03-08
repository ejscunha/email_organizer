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

  @type recipient :: String.t() | {String.t(), String.t()}

  @type message :: %{
          id: String.t(),
          label_ids: [String.t()],
          history_id: integer(),
          from: recipient(),
          recipients: [recipient()],
          subject: String.t(),
          text: String.t(),
          html: String.t(),
          date: DateTime.t()
        }

  @type history_response :: %{
          new_history_id: integer(),
          message_ids: [String.t()]
        }

  @project_id Application.compile_env(:email_organizer, :pub_sub_project_id)
  @topic Application.compile_env(:email_organizer, :pub_sub_topic)

  @spec subscribe_user_emails(String.t()) :: {:ok, subscribe_response()} | {:error, any()}
  def subscribe_user_emails(auth_token) do
    connection = V1.Connection.new(auth_token)
    watch_request = %WatchRequest{topicName: get_topic_name(), labelIds: ["INBOX"]}

    with {:ok, response} <- Api.Users.gmail_users_watch(connection, "me", body: watch_request) do
      {:ok,
       %{
         history_id: response.historyId,
         expires_at:
           response.expiration |> String.to_integer() |> DateTime.from_unix!(:millisecond)
       }}
    end
  end

  @spec list_history(String.t(), integer()) :: {:ok, history_response()} | {:error, any()}
  def list_history(auth_token, history_id) do
    connection = V1.Connection.new(auth_token)

    with {:ok, response} <-
           Api.Users.gmail_users_history_list(
             connection,
             "me",
             startHistoryId: history_id,
             labelId: "INBOX"
           ) do
      message_ids =
        response.history
        |> Enum.flat_map(fn history ->
          history.messages
        end)
        |> Enum.map(& &1.id)
        |> Enum.uniq()

      {:ok, %{new_history_id: response.historyId, message_ids: message_ids}}
    end
  end

  @spec get_message(String.t(), String.t()) :: {:ok, message()} | {:error, any()}
  def get_message(auth_token, id) do
    connection = V1.Connection.new(auth_token)

    with {:ok, response} <-
           Api.Users.gmail_users_messages_get(connection, "me", id, format: "raw"),
         {:ok, message} <- parse_message(response.raw) do
      {:ok,
       %{
         id: id,
         label_ids: response.labelIds,
         history_id: String.to_integer(response.historyId),
         from: Mail.get_from(message),
         recipients: Mail.all_recipients(message),
         subject: Mail.get_subject(message),
         text: get_message_text(message),
         html: get_message_html(message),
         date: Mail.Message.get_header(message, "date")
       }}
    end
  end

  defp get_topic_name do
    "projects/#{Utils.get_config_value(@project_id)}/topics/#{Utils.get_config_value(@topic)}"
  end

  defp parse_message(raw) do
    case Base.url_decode64(raw) do
      {:ok, message} ->
        {:ok, Mail.parse(message)}

      :error ->
        {:error, {:parsing_error, :decoding_message}}
    end
  rescue
    exception -> {:error, {:parsing_error, exception}}
  end

  defp get_message_text(message) do
    with %Mail.Message{body: body} <- Mail.get_text(message) do
      body
    end
  end

  defp get_message_html(message) do
    with %Mail.Message{body: body} <- Mail.get_html(message) do
      body
    end
  end
end
