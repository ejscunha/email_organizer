defmodule EmailOrganizer.Repo.Migrations.RemoveEmailsLabelIdsField do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      remove :label_ids
    end
  end
end
