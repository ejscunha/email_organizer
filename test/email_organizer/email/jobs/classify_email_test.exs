defmodule EmailOrganizer.Email.Jobs.ClassifyEmailTest do
  @moduledoc """
  Test suite for the ClassifyEmail job.
  """

  use EmailOrganizer.DataCase, async: true
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email.Jobs.ArchiveEmail
  alias EmailOrganizer.Email.Jobs.ClassifyEmail
  alias EmailOrganizer.LLM

  describe "enqueue!/1" do
    test "enqueues a job with the correct arguments" do
      email_id = "123"
      assert %Oban.Job{} = ClassifyEmail.enqueue!(email_id)

      assert_enqueued(worker: ClassifyEmail, args: %{email_id: email_id})
    end
  end

  describe "perform/1" do
    test "classifies email successfully" do
      email_id = "123"
      user = insert(:user)
      category = insert(:category)

      email =
        insert(:email,
          external_id: email_id,
          label_ids: ["INBOX"],
          summary: nil,
          user_id: user.id
        )

      expect(LLM, :categorize_email, fn email ->
        assert email.external_id == email_id
        {:ok, %{"category_id" => category.id, "summary" => "Test Summary"}}
      end)

      assert :ok = perform_job(ClassifyEmail, %{email_id: email_id})

      email = EmailOrganizer.Repo.reload(email)

      assert_enqueued(worker: ArchiveEmail, args: %{email_id: email_id, label_ids: ["INBOX"]})

      assert email.label_ids == []
      assert email.summary == "Test Summary"
      assert email.category_id == category.id
    end

    test "returns error if email is not found" do
      email_id = "123"
      assert {:cancel, :email_not_found} = perform_job(ClassifyEmail, %{email_id: email_id})
    end

    test "returns error if email is fails to be classified" do
      email_id = "123"
      insert(:email, external_id: email_id)

      expect(LLM, :categorize_email, fn email ->
        assert email.external_id == email_id
        {:error, :decoding_error}
      end)

      assert {:error, :decoding_error} = perform_job(ClassifyEmail, %{email_id: email_id})
    end

    test "returns error if email is fails to be upserted" do
      email_id = "123"
      insert(:email, external_id: email_id)

      expect(LLM, :categorize_email, fn email ->
        assert email.external_id == email_id
        {:ok, %{"category_id" => 123, "summary" => "Test Summary"}}
      end)

      assert {:error, %Ecto.Changeset{}} = perform_job(ClassifyEmail, %{email_id: email_id})
    end
  end
end
