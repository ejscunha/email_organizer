defmodule EmailOrganizer.Repo do
  use Ecto.Repo,
    otp_app: :email_organizer,
    adapter: Ecto.Adapters.Postgres
end
