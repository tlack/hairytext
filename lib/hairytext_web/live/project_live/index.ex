defmodule HTWeb.ProjectLive.Index do
  use HTWeb, :live_view

  alias HT.Data
  alias HT.Data.Project

  @impl true
  def mount(_params, session, socket) do
    s2 = socket |> HTWeb.SessionSetup.assigns(session)
    {:ok, assign(s2, :projects, fetch_projects())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, Data.get_project!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Projects")
    |> assign(:project, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :set_default, _params) do
    socket
    |> redirect(to: "/examples")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Data.get_project!(id)
    {:ok, _} = Data.delete_project(project)

    {:noreply, assign(socket, :projects, fetch_projects())}
  end

  defp fetch_projects do
    Data.list_projects()
  end
end
