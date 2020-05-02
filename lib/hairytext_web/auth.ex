defmodule HTWeb.Auth do
  def authorize_user(conn, id, pw) when is_binary(id) and is_binary(pw) do
    users = Application.fetch_env!(:hairytext, __MODULE__)[:users]
    if Util.has(users, id) do
      if users[id] == pw do
        conn 
          |> Plug.Conn.assign(:current_user, users[id])
      else
        IO.inspect(:badpw, label: HTWeb_Auth)
        Plug.Conn.halt(conn)
      end
    else
      IO.inspect(:baduser, label: HTWeb_Auth)
      Plug.Conn.halt(conn)
    end
  end
end
