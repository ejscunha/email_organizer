defmodule EmailOrganizer.Repo do
  use Ecto.Repo,
    otp_app: :email_organizer,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
