defmodule EmailOrganizer.Google.Gmail do
  @moduledoc """
  A module for interacting with Gmail.
  """

  require Logger

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Utils
  alias GoogleApi.Gmail.V1
  alias GoogleApi.Gmail.V1.Api
  alias GoogleApi.Gmail.V1.Model.ModifyMessageRequest
  alias GoogleApi.Gmail.V1.Model.WatchRequest
  alias Ueberauth.Strategy.Google.OAuth

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

  @spec subscribe_user_emails(User.t()) :: {:ok, subscribe_response()} | {:error, any()}
  def subscribe_user_emails(user) do
    connection = get_connection(user)

    watch_request = %WatchRequest{
      topicName: get_topic_name(),
      labelIds: ["INBOX"],
      labelFilterBehavior: "include"
    }

    case Api.Users.gmail_users_watch(connection, "me", body: watch_request) do
      {:ok, response} ->
        {:ok,
         %{
           history_id: response.historyId,
           expires_at:
             response.expiration |> String.to_integer() |> DateTime.from_unix!(:millisecond)
         }}

      {:error, %Tesla.Env{status: 401}} ->
        user
        |> update_user_auth_token()
        |> subscribe_user_emails()

      other ->
        other
    end
  end

  @spec list_history(User.t(), integer()) :: {:ok, history_response()} | {:error, any()}
  def list_history(user, history_id) do
    connection = get_connection(user)

    case Api.Users.gmail_users_history_list(
           connection,
           "me",
           startHistoryId: history_id,
           labelId: "INBOX",
           historyType: ["messageAdded"]
         ) do
      {:ok, %{history: history, historyId: history_id}} ->
        message_ids = get_message_ids_from_history(history)
        {:ok, %{new_history_id: history_id, message_ids: message_ids}}

      {:error, %Tesla.Env{status: 401}} ->
        user
        |> update_user_auth_token()
        |> list_history(history_id)

      other ->
        other
    end
  end

  @spec get_message(User.t(), String.t()) :: {:ok, message()} | {:error, any()}
  def get_message(user, id) do
    connection = get_connection(user)

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
    else
      {:error, %Tesla.Env{status: 401}} ->
        user
        |> update_user_auth_token()
        |> get_message(id)

      other ->
        other
    end
  end

  @spec archive_email(User.t(), String.t()) :: :ok | {:error, any()}
  def archive_email(user, id) do
    connection = get_connection(user)
    body = %ModifyMessageRequest{removeLabelIds: ["INBOX"]}

    case Api.Users.gmail_users_messages_modify(connection, "me", id, body: body) do
      {:ok, _response} ->
        :ok

      {:error, %Tesla.Env{status: 401}} ->
        user
        |> update_user_auth_token()
        |> archive_email(id)

      {:error, %Tesla.Env{status: 400} = reason} ->
        Logger.warning(
          "Failing silently to archive email because it's probably already archived",
          email_id: id,
          reason: inspect(reason)
        )

        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_topic_name do
    "projects/#{Utils.get_config_value(@project_id)}/topics/#{Utils.get_config_value(@topic)}"
  end

  defp get_message_ids_from_history(nil), do: []

  defp get_message_ids_from_history(history) do
    history
    |> Enum.flat_map(fn history ->
      history
      |> Map.get(:messagesAdded)
      |> List.wrap()
      |> Enum.map(& &1.message.id)
    end)
    |> Enum.uniq()
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

  defp get_connection(user) do
    now_minus_5_minutes = DateTime.add(DateTime.utc_now(), -5, :minute)

    user =
      case DateTime.compare(user.auth_token_expires_at, now_minus_5_minutes) do
        :lt -> update_user_auth_token(user)
        _other -> user
      end

    V1.Connection.new(user.auth_token)
  end

  defp update_user_auth_token(user) do
    token =
      [strategy: OAuth2.Strategy.Refresh, params: %{"refresh_token" => user.refresh_token}]
      |> OAuth.client()
      |> OAuth2.Client.get_token!()

    case Account.upsert_user(
           user
           |> Map.from_struct()
           |> Map.merge(%{
             auth_token: token.token,
             auth_token_expires_at: token.expires_at
           })
         ) do
      {:ok, user} ->
        user

      {:error, reason} ->
        Logger.error("Error updating user auth token", reason: inspect(reason))
        user
    end
  end
end
