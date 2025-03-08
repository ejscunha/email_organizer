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
      watch_request = %WatchRequest{topicName: "projects/project/topics/topic"}

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
                                                      [startHistoryId: ^history_id] ->
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
                                                      [startHistoryId: ^history_id] ->
        {:ok,
         %{
           historyId: 67_890,
           history: []
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
end
