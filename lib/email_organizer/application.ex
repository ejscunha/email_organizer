defmodule EmailOrganizer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EmailOrganizerWeb.Telemetry,
      EmailOrganizer.Repo,
      {Phoenix.PubSub, name: EmailOrganizer.PubSub},
      {Goth, name: EmailOrganizer.Goth},
      EmailOrganizer.Broadway,
      EmailOrganizer.SubscriptionManager,
      EmailOrganizerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EmailOrganizer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    EmailOrganizerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
