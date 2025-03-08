defmodule EmailOrganizer.Repo.Migrations.AddUsersAuthTokens do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :auth_token, :string
      add :auth_token_expires_at, :utc_datetime
      add :refresh_token, :string
    end
  end
end
