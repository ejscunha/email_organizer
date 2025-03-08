defmodule EmailOrganizer.Email.Jobs.ProcessEmailTest do
  @moduledoc """
  Test suite for the ProcessEmail job.
  """

  use EmailOrganizer.DataCase, async: true
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email.Jobs.ProcessEmail
  alias EmailOrganizer.Google.Gmail

  setup do
    user = insert(:user)
    email_id = "email123"
    {:ok, user: user, email_id: email_id}
  end

  describe "enqueue!/2" do
    test "enqueues a job with the correct arguments", %{user: user, email_id: email_id} do
      assert %Oban.Job{} = ProcessEmail.enqueue!(user, email_id)

      assert_enqueued(worker: ProcessEmail, args: %{user_id: user.id, email_id: email_id})
    end
  end

  describe "perform/1" do
    test "processes email successfully", %{user: user, email_id: email_id} do
      expect(Gmail, :get_message, fn auth_token, id ->
        assert auth_token == user.auth_token
        assert id == email_id

        {:ok, build(:message, id: email_id)}
      end)

      assert :ok =
               perform_job(ProcessEmail, %{
                 "user_id" => user.id,
                 "email_id" => email_id
               })
    end

    test "returns error when user not found", %{email_id: email_id} do
      assert {:cancel, :user_not_found} =
               perform_job(ProcessEmail, %{
                 "user_id" => 999,
                 "email_id" => email_id
               })
    end

    test "returns error when Gmail API fails", %{user: user, email_id: email_id} do
      expect(Gmail, :get_message, fn _auth_token, _id ->
        {:error, "API Error"}
      end)

      assert {:error, "API Error"} =
               perform_job(ProcessEmail, %{
                 "user_id" => user.id,
                 "email_id" => email_id
               })
    end

    test "returns cancel when parsing error occurs", %{user: user, email_id: email_id} do
      expect(Gmail, :get_message, fn _auth_token, _id ->
        {:error, {:parsing_error, "Invalid format"}}
      end)

      assert {:cancel, :parsing_error} =
               perform_job(ProcessEmail, %{
                 "user_id" => user.id,
                 "email_id" => email_id
               })
    end
  end
end
