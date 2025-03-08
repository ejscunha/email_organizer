defmodule EmailOrganizerWeb.IndexLiveTest do
  @moduledoc """
  Test suite for the IndexLive view.
  """

  use EmailOrganizerWeb.LiveViewCase, async: true

  alias EmailOrganizer.Email

  describe "Index page" do
    test "displays user information and categories", %{conn: conn, user: user} do
      category1 = insert(:category, user: user, name: "Work", description: "Work emails")
      _category2 = insert(:category, user: user, name: "Personal", description: "Personal emails")

      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ user.name
      assert html =~ user.email

      assert html =~ "Work"
      assert html =~ "Work emails"
      assert html =~ "Personal"
      assert html =~ "Personal emails"

      assert html =~ "View emails"
      assert has_element?(view, "a[href='/categories/#{category1.id}']")
      assert has_element?(view, "a[href='/categories/#{category1.id}/edit']")

      assert has_element?(
               view,
               "button[phx-click='delete_category'][phx-value-id='#{category1.id}']"
             )
    end

    test "displays empty state when user has no categories", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "You don&#39;t have any categories yet"
      assert html =~ "Create your first category"
    end

    test "can navigate to create new category page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      {:ok, _view, html} =
        view
        |> element("a[href='/categories/new']")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Create New Category"
    end

    test "can delete a category", %{conn: conn, user: user} do
      category = insert(:category, user: user)

      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element("button[phx-click='delete_category'][phx-value-id='#{category.id}']")
      |> render_click()

      assert_raise Ecto.NoResultsError, fn -> Email.get_category!(category.id) end
    end
  end
end
