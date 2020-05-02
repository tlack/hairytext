defmodule HTWeb.SessionSetup do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts
  def call(conn, _opts) do
    if pj = get_session(conn, :cur_project_id) do
      project = HT.Data.get_project!(pj)
      conn 
        |> put_session(:cur_project_id, pj)
        |> put_session(:cur_project, project)
    else
      all_projects = HT.Data.list_projects_or_create_one()
      project = hd all_projects
      conn 
        |> put_session(:cur_project_id, project.id) 
        |> put_session(:cur_project, project)
    end
  end
  def assigns(socket, session) do
    Enum.reduce(Util.key(session), socket,
      (fn k,acc -> Phoenix.LiveView.assign(acc, String.to_atom(k), session[k]) end))
      |> IO.inspect(label: :assigns)
  end
end

