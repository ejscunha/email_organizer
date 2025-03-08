defmodule EmailOrganizerWeb.Plug.Auth do
  @moduledoc """
  This module is used to check if the user is authenticated.
  """

  import Phoenix.Controller
  import Plug.Conn

  alias EmailOrganizer.Account
  alias EmailOrganizer.Account.User

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with user_id when is_integer(user_id) <- get_session(conn, :user_id, :not_found),
         %User{} = user <- Account.get_user(user_id) do
      assign(conn, :current_user, user)
    else
      _other ->
        conn
        |> redirect(to: "/auth/google")
        |> halt()
    end
  end
end
