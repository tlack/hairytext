defmodule HT.Data do
  alias HT.Repo
  alias HT.Data.Example
  def list_examples do
    Repo.all(Example)
  end
  def get_example!(id), do: Repo.get!(Example, id)
  def create_example(attrs \\ %{}) do
    %Example{}
    |> Example.changeset(attrs)
    |> Repo.insert()
  end
  def update_example(%Example{} = example, attrs) do
		IO.inspect({example, attrs}, label: :update_example)
    example
    |> Example.changeset(attrs)
    |> Repo.update()
  end
  def delete_example(%Example{} = example) do
    Repo.delete(example)
  end
  def change_example(%type{} = example, attrs \\ %{}) do
		IO.inspect({type, example}, label: :change_example_v1)
    Example.changeset(example, attrs)
  end
  
  alias HT.Data.Prediction
  def list_predictions do
    Repo.all(Prediction)
  end
  def get_prediction!(id), do: Repo.get!(Prediction, id)
  def create_prediction(attrs \\ %{}) do
    %Prediction{}
    |> Prediction.changeset(attrs)
    |> Repo.insert()
  end
  def update_prediction(%Prediction{} = prediction, attrs) do
    prediction
    |> Prediction.changeset(attrs)
    |> Repo.update()
  end
  def delete_prediction(%Prediction{} = prediction) do
    Repo.delete(prediction)
  end
  def change_prediction(%Prediction{} = prediction, attrs \\ %{}) do
    Prediction.changeset(prediction, attrs)
  end

  alias HT.Data.Project
  def list_projects do
    Repo.all(Project)
  end
  def get_project!(id), do: Repo.get!(Project, id)
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end
end
