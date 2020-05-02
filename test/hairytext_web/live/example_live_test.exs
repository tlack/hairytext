defmodule HTWeb.ExampleLiveTest do
  use HTWeb.ConnCase

  import Phoenix.LiveViewTest

  alias HT.Data

  @create_attrs %{label: "some label", source: "some source", text: "some text"}
  @update_attrs %{label: "some updated label", source: "some updated source", text: "some updated text"}
  @invalid_attrs %{label: nil, source: nil, text: nil}

  defp fixture(:example) do
    {:ok, example} = Data.create_example(@create_attrs)
    example
  end

  defp create_example(_) do
    example = fixture(:example)
    %{example: example}
  end

  describe "Index" do
    setup [:create_example]

    test "lists all examples", %{conn: conn, example: example} do
      {:ok, _index_live, html} = live(conn, Routes.example_index_path(conn, :index))

      assert html =~ "Listing Examples"
      assert html =~ example.label
    end

    test "saves new example", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.example_index_path(conn, :index))

      assert index_live |> element("a", "New Example") |> render_click() =~
        "New Example"

      assert_patch(index_live, Routes.example_index_path(conn, :new))

      assert index_live
             |> form("#example-form", example: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#example-form", example: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.example_index_path(conn, :index))

      assert html =~ "Example created successfully"
      assert html =~ "some label"
    end

    test "updates example in listing", %{conn: conn, example: example} do
      {:ok, index_live, _html} = live(conn, Routes.example_index_path(conn, :index))

      assert index_live |> element("#example-#{example.id} a", "Edit") |> render_click() =~
        "Edit Example"

      assert_patch(index_live, Routes.example_index_path(conn, :edit, example))

      assert index_live
             |> form("#example-form", example: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#example-form", example: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.example_index_path(conn, :index))

      assert html =~ "Example updated successfully"
      assert html =~ "some updated label"
    end

    test "deletes example in listing", %{conn: conn, example: example} do
      {:ok, index_live, _html} = live(conn, Routes.example_index_path(conn, :index))

      assert index_live |> element("#example-#{example.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#example-#{example.id}")
    end
  end

  describe "Show" do
    setup [:create_example]

    test "displays example", %{conn: conn, example: example} do
      {:ok, _show_live, html} = live(conn, Routes.example_show_path(conn, :show, example))

      assert html =~ "Show Example"
      assert html =~ example.label
    end

    test "updates example within modal", %{conn: conn, example: example} do
      {:ok, show_live, _html} = live(conn, Routes.example_show_path(conn, :show, example))

      assert show_live |> element("a", "Edit") |> render_click() =~
        "Edit Example"

      assert_patch(show_live, Routes.example_show_path(conn, :edit, example))

      assert show_live
             |> form("#example-form", example: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#example-form", example: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.example_show_path(conn, :show, example))

      assert html =~ "Example updated successfully"
      assert html =~ "some updated label"
    end
  end
end
