defmodule EmailOrganizerWeb.CategoryLive.NewTest do
  @moduledoc """
  Test suite for the New category page.
  """

  use EmailOrganizerWeb.LiveViewCase, async: true

  alias EmailOrganizer.Email

  describe "New category page" do
    test "renders form for new category", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/categories/new")

      assert html =~ "Create New Category"
      assert html =~ "Name"
      assert html =~ "Description"
    end

    test "validates form inputs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories/new")

      assert view
             |> form("#category-form", category: %{name: "", description: ""})
             |> render_change() =~ "can&#39;t be blank"
    end

    test "creates a new category and redirects", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/categories/new")

      {:ok, _view, html} =
        view
        |> form("#category-form",
          category: %{name: "Test Category", description: "Test Description"}
        )
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Category created successfully"

      categories = Email.list_categories_by_user(user.id)
      assert length(categories) == 1
      assert hd(categories).name == "Test Category"
      assert hd(categories).description == "Test Description"
    end

    test "can navigate back to index page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories/new")

      {:ok, _view, html} =
        view
        |> element("a", "Back to index")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Your Categories"
    end
  end
end
