defmodule EmailOrganizer.BroadwayTest do
  @moduledoc """
  Test suite for the Broadway module.
  """

  use EmailOrganizer.DataCase, async: false
  use Oban.Testing, repo: EmailOrganizer.Repo
  use Mimic

  alias EmailOrganizer.Email.Jobs.CheckUserEmailHistory

  setup :set_mimic_global

  describe "handle_message/3" do
    test "processes an email notification message" do
      email = "test@example.com"
      email_id = "1234567890"
      data = Jason.encode!(%{"emailAddress" => email, "historyId" => email_id})

      ref = Broadway.test_message(EmailOrganizer.Broadway, data)

      assert_receive {:ack, ^ref, [%{data: ^data}], []}

      assert_enqueued(worker: CheckUserEmailHistory, args: %{email: email})
    end
  end
end
