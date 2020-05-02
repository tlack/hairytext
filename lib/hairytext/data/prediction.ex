defmodule HT.Data.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prediction" do
    field :text, :string
    field :label, :string
    field :label_confidence, :float
		field :entities, :map
    timestamps()
  end

  @doc false
  def changeset(example, attrs) do
    example
    |> cast(attrs, [:text, :label, :label_confidence, :entities])
  end
end
