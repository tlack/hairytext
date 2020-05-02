defmodule HT.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :text
      add :labels, :string
      add :entities, :string

      timestamps()
    end

  end
end
