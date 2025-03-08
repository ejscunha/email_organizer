defmodule EmailOrganizer.SubscriptionManagerTest do
  @moduledoc """
  Test suite for the SubscriptionManager module.
  """

  use EmailOrganizer.DataCase, async: true
  use Mimic

  alias EmailOrganizer.Email
  alias EmailOrganizer.SubscriptionManager

  setup do
    pid = start_supervised!({SubscriptionManager, name: :subscription_manager})
    Mimic.allow(Email, self(), pid)
    :ok
  end

  describe "subscription_manager" do
    test "subscribe_user_emails/2 sends a cast message to the GenServer" do
      user = build(:user)

      test_pid = self()

      expect(Email, :subscribe_user_emails, fn ^user ->
        send(test_pid, :subscribe_called)
        :ok
      end)

      SubscriptionManager.subscribe_user_emails(:subscription_manager, user)

      assert_receive :subscribe_called, 500
    end
  end
end
