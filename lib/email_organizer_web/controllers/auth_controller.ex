defmodule EmailOrganizerWeb.AuthController do
  @moduledoc """
  Handles the authentication process for the application.
  """

  use EmailOrganizerWeb, :controller

  alias Ueberauth.Auth
  alias Ueberauth.Strategy.Helpers

  plug Ueberauth

  def request(conn, _params) do
    redirect(conn, external: Helpers.request_url(conn, provider: "google"))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_info = extract_user_info(auth)

    conn
    |> put_session(:user, user_info)
    |> put_flash(:info, "Successfully authenticated as #{user_info.name}")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/auth/failed")
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:user)
    |> render(:logout)
  end

  def failed(conn, _params) do
    render(conn, :failed)
  end

  defp extract_user_info(%Auth{info: info}) do
    %{
      name: info.name,
      email: info.email
    }
  end
end
