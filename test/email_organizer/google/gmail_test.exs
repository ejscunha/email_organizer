defmodule EmailOrganizer.Google.GmailTest do
  @moduledoc """
  Test suite for the Gmail module.
  """

  use ExUnit.Case, async: true
  use Mimic

  alias EmailOrganizer.Google.Gmail
  alias GoogleApi.Gmail.V1
  alias GoogleApi.Gmail.V1.Api
  alias GoogleApi.Gmail.V1.Model.WatchRequest

  describe "subscribe_user_emails/1" do
    test "successfully subscribes to user emails" do
      connection = %Tesla.Client{}

      watch_request = %WatchRequest{
        topicName: "projects/project/topics/topic",
        labelIds: ["INBOX"]
      }

      expect(V1.Connection, :new, fn auth_token ->
        assert auth_token == "test_auth_token"
        connection
      end)

      expires_at =
        DateTime.utc_now()
        |> DateTime.add(3600)
        |> DateTime.truncate(:millisecond)

      expect(Api.Users, :gmail_users_watch, fn ^connection, "me", body: ^watch_request ->
        {:ok,
         %{
           historyId: "test_history_id",
           expiration: expires_at |> DateTime.to_unix(:millisecond) |> Integer.to_string()
         }}
      end)

      result = Gmail.subscribe_user_emails("test_auth_token")

      assert {:ok,
              %{
                history_id: "test_history_id",
                expires_at: ^expires_at
              }} = result
    end

    test "handles API error" do
      expect(V1.Connection, :new, fn _auth_token -> %Tesla.Client{} end)

      expect(Api.Users, :gmail_users_watch, fn _connection, _user_id, _body ->
        {:error, %{status: 400, body: "Bad Request"}}
      end)

      result = Gmail.subscribe_user_emails("test_auth_token")

      assert {:error, %{status: 400, body: "Bad Request"}} = result
    end
  end

  describe "list_history/2" do
    test "successfully retrieves history with messages" do
      connection = %Tesla.Client{}
      history_id = 12_345

      expect(V1.Connection, :new, fn auth_token ->
        assert auth_token == "test_auth_token"
        connection
      end)

      expect(Api.Users, :gmail_users_history_list, fn ^connection,
                                                      "me",
                                                      [
                                                        startHistoryId: ^history_id,
                                                        labelId: "INBOX"
                                                      ] ->
        {:ok,
         %{
           historyId: 67_890,
           history: [
             %{
               messages: [
                 %{id: "msg1"},
                 %{id: "msg2"}
               ]
             },
             %{
               messages: [
                 %{id: "msg2"},
                 %{id: "msg3"}
               ]
             }
           ]
         }}
      end)

      result = Gmail.list_history("test_auth_token", history_id)

      assert {:ok,
              %{
                new_history_id: 67_890,
                message_ids: ["msg1", "msg2", "msg3"]
              }} = result
    end

    test "successfully retrieves history with no messages" do
      connection = %Tesla.Client{}
      history_id = 12_345

      expect(V1.Connection, :new, fn _auth_token -> connection end)

      expect(Api.Users, :gmail_users_history_list, fn ^connection,
                                                      "me",
                                                      [
                                                        startHistoryId: ^history_id,
                                                        labelId: "INBOX"
                                                      ] ->
        {:ok,
         %{
           historyId: 67_890,
           history: nil
         }}
      end)

      result = Gmail.list_history("test_auth_token", history_id)

      assert {:ok,
              %{
                new_history_id: 67_890,
                message_ids: []
              }} = result
    end

    test "handles API error" do
      expect(V1.Connection, :new, fn _auth_token -> %Tesla.Client{} end)

      expect(Api.Users, :gmail_users_history_list, fn _connection, _user_id, _opts ->
        {:error, %{status: 400, body: "Bad Request"}}
      end)

      result = Gmail.list_history("test_auth_token", 12_345)

      assert {:error, %{status: 400, body: "Bad Request"}} = result
    end
  end

  describe "get_message/2" do
    test "successfully retrieves and parses a message" do
      connection = %Tesla.Client{}
      message_id = "msg123"

      expect(V1.Connection, :new, fn auth_token ->
        assert auth_token == "test_auth_token"
        connection
      end)

      raw_email =
        Mail.build()
        |> Mail.put_from({"John Doe", "john@example.com"})
        |> Mail.put_to({"Jane Smith", "jane@example.com"})
        |> Mail.put_cc({"Bob Johnson", "bob@example.com"})
        |> Mail.put_subject("Test Email")
        |> Mail.put_text("Hello World!")
        |> Mail.Message.put_header("date", ~U[2024-01-01 12:00:00Z])
        |> Mail.render()
        |> Base.url_encode64()

      expect(Api.Users, :gmail_users_messages_get, fn ^connection,
                                                      "me",
                                                      ^message_id,
                                                      [format: "raw"] ->
        {:ok,
         %{
           id: message_id,
           labelIds: ["INBOX", "UNREAD"],
           historyId: "98765",
           raw: raw_email
         }}
      end)

      result = Gmail.get_message("test_auth_token", message_id)

      assert {:ok,
              %{
                id: ^message_id,
                label_ids: ["INBOX", "UNREAD"],
                history_id: 98_765,
                from: {"John Doe", "john@example.com"},
                recipients: [
                  {"Jane Smith", "jane@example.com"},
                  {"Bob Johnson", "bob@example.com"}
                ],
                subject: "Test Email",
                text: "Hello World!",
                date: ~U[2024-01-01 12:00:00Z]
              }} = result
    end

    test "handles API error" do
      expect(V1.Connection, :new, fn _auth_token -> %Tesla.Client{} end)

      expect(Api.Users, :gmail_users_messages_get, fn _connection, _user_id, _message_id, _opts ->
        {:error, %{status: 404, body: "Message not found"}}
      end)

      result = Gmail.get_message("test_auth_token", "non_existent_message")

      assert {:error, %{status: 404, body: "Message not found"}} = result
    end

    test "handles message parsing error" do
      connection = %Tesla.Client{}
      message_id = "msg123"

      expect(V1.Connection, :new, fn _auth_token -> connection end)

      invalid_raw_email = "invalid_base64_content"

      expect(Api.Users, :gmail_users_messages_get, fn ^connection,
                                                      "me",
                                                      ^message_id,
                                                      [format: "raw"] ->
        {:ok,
         %{
           id: message_id,
           labelIds: ["INBOX"],
           historyId: "98765",
           raw: invalid_raw_email
         }}
      end)

      result = Gmail.get_message("test_auth_token", message_id)

      assert {:error, {:parsing_error, :decoding_message}} = result
    end
  end
end
