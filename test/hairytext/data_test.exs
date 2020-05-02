defmodule HT.DataTest do
  use HT.DataCase

  alias HT.Data

  describe "examples" do
    alias HT.Data.Example

    @valid_attrs %{label: "some label", source: "some source", text: "some text"}
    @update_attrs %{label: "some updated label", source: "some updated source", text: "some updated text"}
    @invalid_attrs %{label: nil, source: nil, text: nil}

    def example_fixture(attrs \\ %{}) do
      {:ok, example} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Data.create_example()

      example
    end

    test "list_examples/0 returns all examples" do
      example = example_fixture()
      assert Data.list_examples() == [example]
    end

    test "get_example!/1 returns the example with given id" do
      example = example_fixture()
      assert Data.get_example!(example.id) == example
    end

    test "create_example/1 with valid data creates a example" do
      assert {:ok, %Example{} = example} = Data.create_example(@valid_attrs)
      assert example.label == "some label"
      assert example.source == "some source"
      assert example.text == "some text"
    end

    test "create_example/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_example(@invalid_attrs)
    end

    test "update_example/2 with valid data updates the example" do
      example = example_fixture()
      assert {:ok, %Example{} = example} = Data.update_example(example, @update_attrs)
      assert example.label == "some updated label"
      assert example.source == "some updated source"
      assert example.text == "some updated text"
    end

    test "update_example/2 with invalid data returns error changeset" do
      example = example_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_example(example, @invalid_attrs)
      assert example == Data.get_example!(example.id)
    end

    test "delete_example/1 deletes the example" do
      example = example_fixture()
      assert {:ok, %Example{}} = Data.delete_example(example)
      assert_raise Ecto.NoResultsError, fn -> Data.get_example!(example.id) end
    end

    test "change_example/1 returns a example changeset" do
      example = example_fixture()
      assert %Ecto.Changeset{} = Data.change_example(example)
    end
  end

  describe "projects" do
    alias HT.Data.Project

    @valid_attrs %{entities: "some entities", labels: "some labels", name: "some name"}
    @update_attrs %{entities: "some updated entities", labels: "some updated labels", name: "some updated name"}
    @invalid_attrs %{entities: nil, labels: nil, name: nil}

    def project_fixture(attrs \\ %{}) do
      {:ok, project} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Data.create_project()

      project
    end

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Data.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Data.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} = Data.create_project(@valid_attrs)
      assert project.entities == "some entities"
      assert project.labels == "some labels"
      assert project.name == "some name"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      assert {:ok, %Project{} = project} = Data.update_project(project, @update_attrs)
      assert project.entities == "some updated entities"
      assert project.labels == "some updated labels"
      assert project.name == "some updated name"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_project(project, @invalid_attrs)
      assert project == Data.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Data.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Data.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Data.change_project(project)
    end
  end
end
