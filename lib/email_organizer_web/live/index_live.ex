defmodule EmailOrganizerWeb.IndexLive do
  @moduledoc """
  A live view for the index page.
  """

  use EmailOrganizerWeb, :live_view

  alias EmailOrganizer.Email

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    categories = Email.list_categories_by_user(user.id)

    {:ok, assign(socket, categories: categories, user: user)}
  end

  @impl true
  def handle_event("delete_category", %{"id" => id}, socket) do
    category = Email.get_category!(id)

    case Email.delete_category(category) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category deleted successfully")
         |> assign(categories: Email.list_categories_by_user(socket.assigns.user.id))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete category")
         |> assign(categories: Email.list_categories_by_user(socket.assigns.user.id))}
    end
  end
end
