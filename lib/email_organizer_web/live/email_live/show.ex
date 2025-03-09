defmodule EmailOrganizerWeb.EmailLive.Show do
  @moduledoc """
  LiveView for showing email details.
  """

  use EmailOrganizerWeb, :live_view

  alias EmailOrganizer.Email

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    email = Email.get_email!(String.to_integer(id))
    category = Email.get_category!(email.category_id)

    {:ok,
     socket
     |> assign(:email, email)
     |> assign(:category, category)
     |> assign(:page_title, email.subject)}
  end

  @impl true
  def handle_event("delete_email", _, socket) do
    Email.delete_emails([socket.assigns.email.id])

    {:noreply,
     socket
     |> put_flash(:info, "Email deleted successfully")
     |> push_navigate(to: ~p"/categories/#{socket.assigns.category.id}")}
  end

  @impl true
  def handle_event("unsubscribe_email", _, socket) do
    # This is a placeholder for future implementation
    {:noreply,
     put_flash(socket, :info, "Unsubscribe feature will be implemented in a future update")}
  end
end
