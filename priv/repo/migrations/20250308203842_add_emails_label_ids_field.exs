defmodule EmailOrganizer.Repo.Migrations.AddEmailsLabelIdsField do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      add :label_ids, {:array, :string}
    end
  end
end
