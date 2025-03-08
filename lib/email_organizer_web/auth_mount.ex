defmodule EmailOrganizerWeb.AuthMount do
  @moduledoc """
  Mounts the current user on the socket.
  """

  use EmailOrganizerWeb, :live_mount

  alias EmailOrganizer.Account

  def on_mount(:default, _params, session, socket) do
    with {:ok, user_id} <- Map.fetch(session, "user_id"),
         %Account.User{} = user <- Account.get_user(user_id) do
      {:cont, assign(socket, :current_user, user)}
    else
      _ -> {:halt, redirect(socket, to: ~p"/auth/google")}
    end
  end
end
