defmodule EmailOrganizer.Email.Jobs.ArchiveEmailTest do
  @moduledoc """
  Test suite for the ArchiveEmail job.
  """

  use EmailOrganizer.DataCase, async: true
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email.Jobs.ArchiveEmail
  alias EmailOrganizer.Google.Gmail

  describe "enqueue!/2" do
    test "enqueues the job" do
      email_id = "123"

      assert %Oban.Job{} = ArchiveEmail.enqueue!(email_id)

      assert_enqueued(worker: ArchiveEmail, args: %{email_id: email_id})
    end

    test "does not enqueue duplicate jobs" do
      email_id = "123"

      ArchiveEmail.enqueue!(email_id)

      assert_enqueued(worker: ArchiveEmail, args: %{email_id: email_id})

      ArchiveEmail.enqueue!(email_id)

      assert_enqueued(worker: ArchiveEmail, args: %{email_id: email_id})
      assert [%Oban.Job{}] = all_enqueued()
    end
  end

  describe "perform!/1" do
    test "archives the email" do
      email_id = "123"
      user = insert(:user)
      insert(:email, external_id: email_id, user_id: user.id)

      expect(Gmail, :archive_email, fn ^user, ^email_id ->
        :ok
      end)

      assert :ok = perform_job(ArchiveEmail, %{email_id: email_id})
    end

    test "returns an error if the email is not found" do
      assert {:cancel, :email_not_found} = perform_job(ArchiveEmail, %{email_id: "123"})
    end

    test "returns an error if the email is not archived" do
      user = insert(:user)
      email = insert(:email, external_id: "123", user_id: user.id)

      expect(Gmail, :archive_email, fn _user, _email_id ->
        {:error, "API Error"}
      end)

      assert {:error, "API Error"} = perform_job(ArchiveEmail, %{email_id: email.external_id})
    end
  end
end
