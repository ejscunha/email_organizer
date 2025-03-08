defmodule EmailOrganizerWeb.CategoryLive.EditTest do
  @moduledoc """
  Test suite for the Edit category page.
  """

  use EmailOrganizerWeb.LiveViewCase, async: true

  alias EmailOrganizer.Email

  describe "Edit category page" do
    setup %{user: user} do
      category =
        insert(:category, user: user, name: "Original Name", description: "Original Description")

      %{category: category}
    end

    test "renders form with category data", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/categories/#{category.id}/edit")

      assert html =~ "Edit Category"
      assert html =~ category.name
      assert html =~ category.description
    end

    test "validates form inputs", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}/edit")

      assert view
             |> form("#category-form", category: %{name: "", description: ""})
             |> render_change() =~ "can&#39;t be blank"
    end

    test "updates a category and redirects", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}/edit")

      {:ok, _view, html} =
        view
        |> form("#category-form",
          category: %{name: "Updated Name", description: "Updated Description"}
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Category updated successfully"

      updated_category = Email.get_category!(category.id)
      assert updated_category.name == "Updated Name"
      assert updated_category.description == "Updated Description"
    end

    test "can navigate back to index page", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}/edit")

      {:ok, _view, html} =
        view
        |> element("a", "Back to index")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Your Categories"
    end
  end
end
