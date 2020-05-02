defmodule HT.Data.Example do
  use Ecto.Schema
  import Ecto.Changeset

  schema "examples" do
    field :text, :string
    field :label, :string
		field :entities, :map
    field :source, :string
		field :status, :string
		field :image, :string
		field :project, :string
    timestamps()
  end

  @doc false
  def changeset(%HT.Data.Example{} = example, attrs) do
		IO.inspect({example, attrs}, label: :example_changeset)
    example
    |> cast(attrs, [:text, :label, :entities, :source, :status, :project])
    |> validate_required([:text])
		|> IO.inspect(label: :example_changeset_after)
  end
end
