defmodule EmailOrganizerWeb.Plug.Auth do
  @moduledoc """
  This module is used to check if the user is authenticated.
  """

  import Phoenix.Controller
  import Plug.Conn

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    case get_session(conn, :user, :not_found) do
      :not_found ->
        query_string = if conn.query_string != "", do: "?#{conn.query_string}", else: ""
        current_path = "#{conn.request_path}#{query_string}"

        conn
        |> put_session(:callback_url, current_path)
        |> redirect(to: "/auth/google")
        |> halt()

      user ->
        assign(conn, :current_user, user)
    end
  end
end
