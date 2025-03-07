defmodule EmailOrganizer.SubscriptionManager do
  @moduledoc """
  Manages user subscriptions to email changes.
  """

  use GenServer

  alias EmailOrganizer.Account.User

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec subscribe_user_emails(GenServer.server(), User.t(), String.t()) :: :ok
  def subscribe_user_emails(name \\ __MODULE__, user, auth_token) do
    GenServer.cast(name, {:subscribe_user_emails, user, auth_token})
  end

  @impl true
  def init(:ok) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:subscribe_user_emails, user, auth_token}, state) do
    EmailOrganizer.Email.subscribe_user_emails(user, auth_token)
    {:noreply, state}
  end
end
