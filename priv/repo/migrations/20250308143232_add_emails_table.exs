defmodule EmailOrganizer.Repo.Migrations.AddEmailsTable do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :external_id, :string
      add :from, :string
      add :recipients, {:array, :string}
      add :subject, :string
      add :text, :string
      add :date, :utc_datetime_usec
      add :summary, :string
      add :user_id, references(:users)
      add :category_id, references(:categories)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:emails, [:external_id])
  end
end
