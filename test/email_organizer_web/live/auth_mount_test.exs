defmodule EmailOrganizerWeb.AuthMountTest do
  @moduledoc """
  Test suite for the AuthMount hook.
  """

  use EmailOrganizerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "AuthMount hook" do
    test "redirects to login when user is not authenticated", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, %{})

      assert {:error, {:redirect, %{to: "/auth/google"}}} = live(conn, ~p"/")
    end

    test "allows access when user is authenticated", %{conn: conn} do
      user = insert(:user)
      conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: user.id})

      assert {:ok, _view, _html} = live(conn, ~p"/")
    end

    test "assigns current_user to socket when authenticated", %{conn: conn} do
      user = insert(:user)
      conn = Phoenix.ConnTest.init_test_session(conn, %{user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/")

      assert render(view) =~ user.name
      assert render(view) =~ user.email
    end
  end
end
