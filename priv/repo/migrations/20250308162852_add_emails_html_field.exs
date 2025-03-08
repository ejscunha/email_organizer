defmodule EmailOrganizer.Repo.Migrations.AddEmailsHtmlField do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      add :html, :text
      modify :text, :text
    end
  end
end
