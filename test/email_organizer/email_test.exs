defmodule EmailOrganizer.EmailTest do
  @moduledoc """
  Test suite for the Email module.
  """

  use EmailOrganizer.DataCase, async: true

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Category

  describe "categories" do
    @invalid_attrs %{name: nil, description: nil}

    test "list_categories/0 returns all categories" do
      categories = insert_list(3, :category)
      assert Email.list_categories() == categories
    end

    test "get_category!/1 returns the category with given id" do
      category = insert(:category)
      assert Email.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      user_id = insert(:user).id

      valid_attrs = %{
        name: "Test Category",
        description: "Test Description",
        user_id: user_id
      }

      assert {:ok,
              %Category{name: "Test Category", description: "Test Description", user_id: ^user_id}} =
               Email.create_category(valid_attrs)
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Email.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = insert(:category, user: build(:user))

      update_attrs = %{
        name: "Updated Category",
        description: "Updated Description"
      }

      assert {:ok, %Category{name: "Updated Category", description: "Updated Description"}} =
               Email.update_category(category, update_attrs)
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = insert(:category)
      assert {:error, %Ecto.Changeset{}} = Email.update_category(category, @invalid_attrs)
      assert category == Email.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = insert(:category)
      assert {:ok, %Category{}} = Email.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Email.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = insert(:category)
      assert %Ecto.Changeset{} = Email.change_category(category)
    end
  end

  describe "subscriptions" do
    setup do
      user = insert(:user)
      {:ok, user: user}
    end

    test "upsert_subscription/1 with valid data creates a subscription", %{user: user} do
      expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

      valid_attrs = %{
        last_id: 123,
        expires_at: expires_at,
        user_id: user.id
      }

      assert {:ok, %Subscription{} = subscription} = Email.upsert_subscription(valid_attrs)
      assert subscription.last_id == 123
      assert subscription.user_id == user.id
      assert DateTime.compare(subscription.expires_at, expires_at) == :eq
    end

    test "upsert_subscription/1 with invalid data returns error changeset" do
      invalid_attrs = %{last_id: nil, expires_at: nil, user_id: nil}
      assert {:error, %Ecto.Changeset{}} = Email.upsert_subscription(invalid_attrs)
    end

    test "upsert_subscription/1 updates existing subscription", %{user: user} do
      subscription = insert(:subscription, user: user)

      new_expires_at = DateTime.add(DateTime.utc_now(), 14, :day)

      {:ok, updated_subscription} =
        Email.upsert_subscription(%{
          last_id: 123,
          expires_at: new_expires_at,
          user_id: user.id
        })

      assert updated_subscription.id == subscription.id
      assert updated_subscription.last_id == 123
      assert DateTime.compare(updated_subscription.expires_at, new_expires_at) == :eq
    end

    test "get_subscription_by_user_id/1 returns subscription for existing user", %{user: user} do
      subscription = insert(:subscription, user_id: user.id)

      assert Email.get_subscription_by_user_id(user.id) == subscription
    end

    test "get_subscription_by_user_id/1 returns nil for non-existing user" do
      assert Email.get_subscription_by_user_id(0) == nil
    end

    test "subscribe_user_emails/2 creates new subscription when none exists", %{user: user} do
      expires_at = DateTime.add(DateTime.utc_now(), 7, :day)

      expect(Gmail, :subscribe_user_emails, fn "test_token" ->
        {:ok, %{history_id: 123, expires_at: expires_at}}
      end)

      assert :ok = Email.subscribe_user_emails(user, "test_token")

      subscription = Email.get_subscription_by_user_id(user.id)
      assert subscription.last_id == 123
      assert DateTime.compare(subscription.expires_at, expires_at) == :eq
    end

    test "subscribe_user_emails/2 returns :ok when subscription is still active", %{user: user} do
      insert(:subscription, user: user, expires_at: DateTime.add(DateTime.utc_now(), 7, :day))

      reject(Gmail, :subscribe_user_emails, 1)

      assert :ok = Email.subscribe_user_emails(user, "test_token")
    end

    test "subscribe_user_emails/2 returns error when Gmail API fails", %{user: user} do
      expect(Gmail, :subscribe_user_emails, fn _token ->
        {:error, "API Error"}
      end)

      assert :error = Email.subscribe_user_emails(user, "test_token")
    end
  end
end
