defmodule EmailOrganizer.BroadwayTest do
  @moduledoc """
  Test suite for the Broadway module.
  """

  use EmailOrganizer.DataCase, async: false
  use Mimic

  setup :set_mimic_global

  describe "handle_message/3" do
    test "processes an email notification message" do
      email = "test@example.com"
      email_id = "1234567890"
      data = Jason.encode!(%{"emailAddress" => email, "historyId" => email_id})

      test_pid = self()

      expect(EmailOrganizer.Email, :process_email_notification, fn ^email, ^email_id ->
        send(test_pid, {:email_notification, email, email_id})
        :ok
      end)

      ref = Broadway.test_message(EmailOrganizer.Broadway, data)

      assert_receive {:email_notification, ^email, ^email_id}
      assert_receive {:ack, ^ref, [%{data: ^data}], []}
    end
  end
end
