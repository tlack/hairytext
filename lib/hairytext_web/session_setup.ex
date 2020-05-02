defmodule HTWeb.SessionSetup do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts
  def call(conn, _opts) do
    with pj when is_binary(pj) <- get_session(conn, :cur_project_id),
         project when is_struct(project) <- HT.Data.get_project!(pj) do
      IO.inspect(conn, label: :sess_ok)
        |> put_session(:cur_project_id, pj)
        |> put_session(:cur_project, project)
    else 
      _any -> 
        all_projects = HT.Data.list_projects_or_create_one()
          |> IO.inspect(label: :new?)
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

