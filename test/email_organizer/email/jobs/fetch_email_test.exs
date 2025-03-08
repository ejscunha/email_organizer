defmodule EmailOrganizer.Email.Jobs.FetchEmailTest do
  @moduledoc """
  Test suite for the FetchEmail job.
  """

  use EmailOrganizer.DataCase, async: true
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Email, as: EmailRecord
  alias EmailOrganizer.Email.Jobs.FetchEmail
  alias EmailOrganizer.Google.Gmail

  setup do
    user = insert(:user)
    email_id = "email123"
    {:ok, user: user, email_id: email_id}
  end

  describe "enqueue!/2" do
    test "enqueues a job with the correct arguments", %{user: user, email_id: email_id} do
      assert %Oban.Job{} = FetchEmail.enqueue!(user, email_id)

      assert_enqueued(worker: FetchEmail, args: %{user_id: user.id, email_id: email_id})
    end
  end

  describe "perform/1" do
    test "fetches email successfully", %{user: user, email_id: email_id} do
      expect(Gmail, :get_message, fn auth_token, id ->
        assert auth_token == user.auth_token
        assert id == email_id

        {:ok, build(:message, id: email_id)}
      end)

      assert :ok =
               perform_job(FetchEmail, %{
                 "user_id" => user.id,
                 "email_id" => email_id
               })

      assert %EmailRecord{} = Email.get_email_by_external_id(email_id)
    end

    test "returns error when user not found", %{email_id: email_id} do
      assert {:cancel, :user_not_found} =
               perform_job(FetchEmail, %{
                 "user_id" => 999,
                 "email_id" => email_id
               })
    end

    test "returns error when Gmail API fails", %{user: user, email_id: email_id} do
      expect(Gmail, :get_message, fn _auth_token, _id ->
        {:error, "API Error"}
      end)

      assert {:error, "API Error"} =
               perform_job(FetchEmail, %{
                 "user_id" => user.id,
                 "email_id" => email_id
               })
    end

    test "returns cancel when parsing error occurs", %{user: user, email_id: email_id} do
      expect(Gmail, :get_message, fn _auth_token, _id ->
        {:error, {:parsing_error, "Invalid format"}}
      end)

      assert {:cancel, :parsing_error} =
               perform_job(FetchEmail, %{
                 "user_id" => user.id,
                 "email_id" => email_id
               })
    end
  end
end
