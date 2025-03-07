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
end
