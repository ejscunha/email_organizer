defmodule EmailOrganizerWeb.CategoryLive.Show do
  @moduledoc """
  LiveView for showing a category and its emails.
  """

  use EmailOrganizerWeb, :live_view

  alias EmailOrganizer.Email

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    category = Email.get_category!(id)

    {:ok,
     socket
     |> assign(:category, category)
     |> assign(:page_title, category.name)
     |> assign(:emails, [])
     |> assign(:selected_emails, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "10")
    sort_by = (params["sort_by"] || "date") |> String.to_existing_atom()
    sort_order = (params["sort_order"] || "desc") |> String.to_existing_atom()

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:page_size, page_size)
     |> assign(:sort_by, sort_by)
     |> assign(:sort_order, sort_order)
     |> fetch_emails()}
  end

  @impl true
  def handle_event("select_email", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected_emails = socket.assigns.selected_emails

    selected_emails =
      if id in selected_emails do
        List.delete(selected_emails, id)
      else
        [id | selected_emails]
      end

    {:noreply, assign(socket, :selected_emails, selected_emails)}
  end

  def handle_event("select_all", %{"all" => "true"}, socket) do
    email_ids = Enum.map(socket.assigns.emails.entries, & &1.id)
    {:noreply, assign(socket, :selected_emails, email_ids)}
  end

  def handle_event("select_all", %{"all" => "false"}, socket) do
    {:noreply, assign(socket, :selected_emails, [])}
  end

  def handle_event("delete_selected", _, socket) do
    Email.delete_emails(socket.assigns.selected_emails)

    {:noreply,
     socket
     |> put_flash(:info, "Emails deleted successfully")
     |> assign(:selected_emails, [])
     |> patch_url()}
  end

  def handle_event("unsubscribe_selected", _, socket) do
    Email.unsubscribe_from_emails(socket.assigns.selected_emails, self())

    {:noreply,
     socket
     |> put_flash(:info, "Emails will be unsubscribed in the background")
     |> assign(:selected_emails, [])}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    current_sort_by = socket.assigns.sort_by |> Atom.to_string()
    current_sort_order = socket.assigns.sort_order

    {sort_by, sort_order} =
      if field == current_sort_by do
        {String.to_existing_atom(field), if(current_sort_order == :asc, do: :desc, else: :asc)}
      else
        {String.to_existing_atom(field), :asc}
      end

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_order, sort_order)
     |> patch_url()}
  end

  @impl true
  def handle_info({:unsubscribed, email}, socket) do
    {:noreply,
     put_flash(socket, :info, "Email with subject #{email.subject} unsubscribed successfully")}
  end

  def handle_info({:no_unsubscribe_link_found, email}, socket) do
    {:noreply,
     put_flash(socket, :info, "No unsubscribe link found for email with subject #{email.subject}")}
  end

  def handle_info({:failed_to_unsubscribe, email}, socket) do
    {:noreply,
     put_flash(socket, :error, "Failed to unsubscribe from email with subject #{email.subject}")}
  end

  defp fetch_emails(socket) do
    %{
      category: category,
      page: page,
      page_size: page_size,
      sort_by: sort_by,
      sort_order: sort_order
    } =
      socket.assigns

    emails =
      Email.list_emails_by_category(category.id, %{
        page: page,
        page_size: page_size,
        sort_by: sort_by,
        sort_order: sort_order
      })

    assign(socket, :emails, emails)
  end

  defp patch_url(socket) do
    query_string =
      "page=#{socket.assigns.page}&page_size=#{socket.assigns.page_size}&sort_by=#{socket.assigns.sort_by}&sort_order=#{socket.assigns.sort_order}"

    push_patch(socket, to: "/categories/#{socket.assigns.category.id}?#{query_string}")
  end
end
