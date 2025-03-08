defmodule EmailOrganizerWeb.CategoryLive.New do
  @moduledoc """
  LiveView for creating a new category.
  """
  use EmailOrganizerWeb, :live_view

  alias EmailOrganizer.Email
  alias EmailOrganizer.Email.Category

  @impl true
  def mount(_params, _session, socket) do
    changeset = Email.change_category(%Category{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    category_params = Map.put(category_params, "user_id", socket.assigns.current_user.id)

    case Email.create_category(category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :save))}
    end
  end

  def handle_event("validate", %{"category" => category_params}, socket) do
    category_params = Map.put(category_params, "user_id", socket.assigns.current_user.id)

    changeset =
      %Category{}
      |> Email.change_category(category_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end
end
