defmodule EmailOrganizerWeb.PageControllerTest do
  @moduledoc """
  Test suite for the PageController.
  """

  use EmailOrganizerWeb.ConnCase

  alias Plug.Conn

  test "GET /", %{conn: conn} do
    conn =
      conn
      |> Conn.put_session(:user, %{name: "Test User", email: "test@example.com"})
      |> get(~p"/")

    assert html_response(conn, 200) =~ "TODO"
  end
end
