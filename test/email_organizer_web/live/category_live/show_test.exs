defmodule EmailOrganizerWeb.CategoryLive.ShowTest do
  @moduledoc """
  Test suite for the Show category page.
  """

  use EmailOrganizerWeb.LiveViewCase, async: true

  describe "Show category page" do
    setup %{user: user} do
      category =
        insert(:category, user: user, name: "Test Category", description: "Test Description")

      %{category: category}
    end

    test "displays category details", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/categories/#{category.id}")

      assert html =~ category.name
      assert html =~ category.description
      assert html =~ "Emails in this category"
    end

    test "has link to edit category", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Edit Category")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Edit Category"
    end

    test "can navigate back to index page", %{conn: conn, category: category} do
      {:ok, view, _html} = live(conn, ~p"/categories/#{category.id}")

      {:ok, _view, html} =
        view
        |> element("a", "Back to index")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Your Categories"
    end

    test "shows placeholder for email list", %{conn: conn, category: category} do
      {:ok, _view, html} = live(conn, ~p"/categories/#{category.id}")

      assert html =~ "Email list will be implemented in a future update"
    end
  end
end
