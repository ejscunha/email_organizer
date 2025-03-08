defmodule EmailOrganizer.Email.Jobs.CheckUserEmailHistoryTest do
  @moduledoc """
  Test suite for the CheckUserEmailHistory job.
  """

  use EmailOrganizer.DataCase, async: true
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Jobs.CheckUserEmailHistory
  alias EmailOrganizer.Email.Jobs.ProcessEmail
  alias EmailOrganizer.Email.Subscription
  alias EmailOrganizer.Google.Gmail

  setup do
    user = insert(:user, email: "test@example.com")
    subscription = insert(:subscription, user: user, last_id: 123)
    {:ok, user: user, subscription: subscription}
  end

  describe "enqueue!/1" do
    test "enqueues a job with the correct arguments" do
      email = "test@example.com"
      assert %Oban.Job{} = CheckUserEmailHistory.enqueue!(email)

      assert_enqueued(worker: CheckUserEmailHistory, args: %{email: email})
    end
  end

  describe "perform/1" do
    test "processes email history successfully", %{user: user, subscription: subscription} do
      email = user.email
      message_ids = ["msg1", "msg2", "msg3"]
      new_history_id = 456

      expect(Gmail, :list_history, fn auth_token, last_id ->
        assert auth_token == user.auth_token
        assert last_id == subscription.last_id
        {:ok, build(:history, message_ids: message_ids, new_history_id: new_history_id)}
      end)

      assert :ok =
               perform_job(CheckUserEmailHistory, %{
                 "email" => email
               })

      assert Enum.all?(message_ids, fn message_id ->
               assert_enqueued(
                 worker: ProcessEmail,
                 args: %{user_id: user.id, email_id: message_id}
               )
             end)

      assert %Subscription{last_id: ^new_history_id} = Repo.reload(subscription)
    end

    test "returns error when user not found" do
      email = "nonexistent@example.com"

      assert {:cancel, :user_not_found} =
               perform_job(CheckUserEmailHistory, %{
                 "email" => email
               })
    end

    test "returns error when subscription not found" do
      user = insert(:user, email: "other@example.com")

      assert {:cancel, :subscription_not_found} =
               perform_job(CheckUserEmailHistory, %{
                 "email" => user.email
               })
    end

    test "returns error when Gmail API fails", %{user: user} do
      expect(Gmail, :list_history, fn _auth_token, _last_id ->
        {:error, "API Error"}
      end)

      assert {:error, "API Error"} =
               perform_job(CheckUserEmailHistory, %{
                 "email" => user.email
               })
    end

    test "returns error when updating subscription fails", %{user: user} do
      expect(Gmail, :list_history, fn _auth_token, _last_id ->
        {:ok, build(:history)}
      end)

      expect(Email, :update_subscription_last_id, fn _sub_id, _history_id ->
        {:error, "Database Error"}
      end)

      assert {:error, "Database Error"} =
               perform_job(CheckUserEmailHistory, %{
                 "email" => user.email
               })
    end
  end
end
