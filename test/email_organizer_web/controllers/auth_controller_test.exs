defmodule EmailOrganizerWeb.AuthControllerTest do
  @moduledoc """
  Test suite for the AuthController.
  """

  use EmailOrganizerWeb.ConnCase, async: true

  alias Phoenix.Flash

  defp mock_ueberauth_failure do
    %Ueberauth.Failure{
      errors: [%Ueberauth.Failure.Error{message: "Failed to authenticate"}]
    }
  end

  describe "request/2" do
    test "redirects to Google OAuth", %{conn: conn} do
      conn = get(conn, ~p"/auth/google")
      assert redirected_to(conn) =~ "google"
    end
  end

  describe "callback/2 with successful authentication" do
    test "stores user in session and redirects to root path", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> assign(:ueberauth_auth, %Ueberauth.Auth{
          info: %{
            name: user.name,
            email: user.email
          }
        })
        |> get(~p"/auth/google/callback")

      assert get_session(conn, :user_id) == user.id

      assert Flash.get(conn.assigns.flash, :info) =~ "Successfully authenticated as #{user.name}"

      assert redirected_to(conn) == "/"
    end
  end

  describe "callback/2 with failed authentication" do
    test "sets error flash and redirects to auth_failed path", %{conn: conn} do
      conn =
        conn
        |> assign(:ueberauth_failure, mock_ueberauth_failure())
        |> get(~p"/auth/google/callback")

      assert Flash.get(conn.assigns.flash, :error) == "Failed to authenticate."

      assert redirected_to(conn) == "/auth/failed"
    end
  end

  describe "logout/2" do
    test "renders the logout template", %{conn: conn} do
      conn = get(conn, ~p"/auth/logout")
      assert html_response(conn, 200) =~ "Logged out"
    end
  end

  describe "auth_failed/2" do
    test "renders the auth_failed template", %{conn: conn} do
      conn = get(conn, ~p"/auth/failed")
      assert html_response(conn, 200) =~ "Authentication Failed"
    end
  end
end
