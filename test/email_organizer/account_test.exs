defmodule EmailOrganizer.AccountTest do
  @moduledoc """
  Test suite for the Account context
  """

  use EmailOrganizer.DataCase, async: true

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User

  describe "EmailOrganizer.Account" do
    test "get_user/1 returns the user with given id" do
      user = insert(:user)
      assert Account.get_user(user.id) == user
    end

    test "get_user_by_email/1 returns the user with given email" do
      user = insert(:user)
      assert Account.get_user_by_email(user.email) == user
    end

    test "upsert_user/1 upserts a user" do
      assert {:ok, %User{email: "test@example.com", name: "Test User"} = user} =
               Account.upsert_user(%{email: "test@example.com", name: "Test User"})

      assert {:ok, %User{email: "test@example.com", name: "Test User 2"}} =
               Account.upsert_user(%{email: "test@example.com", name: "Test User 2"})

      assert %User{email: "test@example.com", name: "Test User 2"} =
               Account.get_user(user.id)
    end
  end
end
