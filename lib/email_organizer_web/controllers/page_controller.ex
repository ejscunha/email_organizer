defmodule EmailOrganizerWeb.PageController do
  use EmailOrganizerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
