defmodule HT.Repo.Migrations.CreateExamples do
  use Ecto.Migration

  def change do
    create table(:examples) do
      add :text, :text
      add :label, :string
      add :source, :string

      timestamps()
    end

  end
end
