defmodule HT.Data.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :entities, :string
    field :labels, :string
    field :name, :string
    field :project_type, :string
    field :instructions, :string

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :labels, :entities, :project_type, :instructions])
    |> validate_required([:name])
  end
end
