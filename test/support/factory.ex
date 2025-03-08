defmodule EmailOrganizer.Support.Factory do
  @moduledoc """
  Factory for creating test data
  """

  use ExMachina.Ecto, repo: EmailOrganizer.Repo

  alias EmailOrganizer.Account.User
  alias EmailOrganizer.Email.Category
  alias EmailOrganizer.Email.Subscription

  def user_factory do
    %User{
      email: sequence(:email, &"user-#{&1}@example.com"),
      name: sequence(:name, &"User #{&1}"),
      auth_token: sequence(:auth_token, &"auth_token_#{&1}"),
      auth_token_expires_at: DateTime.add(DateTime.utc_now(), 7, :day),
      refresh_token: sequence(:refresh_token, &"refresh_token_#{&1}")
    }
  end

  def category_factory do
    %Category{
      name: sequence(:name, &"Category #{&1}"),
      description: sequence(:description, &"Description #{&1}")
    }
  end

  def subscription_factory do
    %Subscription{
      last_id: sequence(:last_id, & &1),
      expires_at: DateTime.add(DateTime.utc_now(), 7, :day)
    }
  end

  def history_factory do
    %{
      new_history_id: sequence(:new_history_id, & &1),
      message_ids: ["message-1", "message-2", "message-3"]
    }
  end

  def message_factory do
    %{
      id: sequence(:id, &"message-#{&1}"),
      label_ids: ["INBOX"],
      history_id: sequence(:history_id, & &1),
      from: "test@example.com",
      recipients: ["test@example.com"],
      subject: "Test Email",
      text: "This is a test email.",
      date: ~U[2021-01-01 00:00:00Z]
    }
  end
end
