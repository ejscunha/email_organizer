defmodule EmailOrganizerWeb.CategoryLive.Show do
  @moduledoc """
  LiveView for showing a category and its emails.
  """

  use EmailOrganizerWeb, :live_view

  alias EmailOrganizer.Email

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    category = Email.get_category!(id)

    {:ok, assign(socket, category: category)}
  end
end
