defmodule EmailOrganizerWeb.PageControllerTest do
  @moduledoc """
  Test suite for the PageController.
  """

  use EmailOrganizerWeb.ConnCase

  alias Plug.Conn

  test "GET /", %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> Conn.put_session(:user_id, user.id)
      |> get(~p"/")

    assert html_response(conn, 200) =~ "TODO"
  end
end
