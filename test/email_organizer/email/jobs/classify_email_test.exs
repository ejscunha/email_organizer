defmodule EmailOrganizer.Email.Jobs.ClassifyEmailTest do
  @moduledoc """
  Test suite for the ClassifyEmail job.
  """

  use EmailOrganizer.DataCase, async: true
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email.Jobs.ClassifyEmail

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
      insert(:email, external_id: email_id)

      assert :ok = perform_job(ClassifyEmail, %{email_id: email_id})
    end
  end
end
