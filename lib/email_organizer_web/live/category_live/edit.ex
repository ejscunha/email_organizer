defmodule EmailOrganizerWeb.CategoryLive.Edit do
  @moduledoc """
  LiveView for editing a category.
  """
  use EmailOrganizerWeb, :live_view

  alias EmailOrganizer.Email

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    category = Email.get_category!(id)
    changeset = Email.change_category(category)

    {:ok, assign(socket, form: to_form(changeset), category: category)}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    case Email.update_category(socket.assigns.category, category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category updated successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :save))}
    end
  end

  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset = Email.change_category(socket.assigns.category, category_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end
end
