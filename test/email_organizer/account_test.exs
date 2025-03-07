defmodule EmailOrganizer.AccountTest do
  @moduledoc """
  Test suite for the Account context
  """

  use EmailOrganizer.DataCase, async: true

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User

  describe "EmailOrganizer.Account" do
    @invalid_attrs %{email: nil, name: nil}

    test "list_users/0 returns all users" do
      users = insert_list(3, :user)
      assert Account.list_users() == users
    end

    test "get_user!/1 returns the user with given id" do
      user = insert(:user)
      assert Account.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{email: "test@example.com", name: "Test User"}

      assert {:ok, %User{email: "test@example.com", name: "Test User"}} =
               Account.create_user(valid_attrs)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Account.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)
      update_attrs = %{email: "test2@example.com", name: "Test User 2"}

      assert {:ok, %User{email: "test2@example.com", name: "Test User 2"}} =
               Account.update_user(user, update_attrs)
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Account.update_user(user, @invalid_attrs)
      assert user == Account.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Account.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Account.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = build(:user)
      assert %Ecto.Changeset{} = Account.change_user(user)
    end
  end
end
