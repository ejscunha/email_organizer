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
    Email.unsubscribe_from_emails([socket.assigns.email.id], self())
    {:noreply, put_flash(socket, :info, "Email will be unsubscribed in the background")}
  end

  @impl true
  def handle_info({:unsubscribed, email}, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> put_flash(:info, "Email with subject #{email.subject} unsubscribed successfully")}
  end

  def handle_info({:no_unsubscribe_link_found, email}, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> put_flash(:info, "No unsubscribe link found for email with subject #{email.subject}")}
  end

  def handle_info({:failed_to_unsubscribe, email}, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> put_flash(:error, "Failed to unsubscribe from email with subject #{email.subject}")}
  end
end
