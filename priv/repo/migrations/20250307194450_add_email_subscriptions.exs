defmodule EmailOrganizer.Repo.Migrations.AddEmailSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :last_id, :integer
      add :expires_at, :utc_datetime_usec

      timestamps(type: :utc_datetime)
    end

    create unique_index(:subscriptions, [:user_id])
  end
end
