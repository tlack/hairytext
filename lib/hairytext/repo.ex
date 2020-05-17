defmodule HT.Repo.State do
  defstruct fname: "", ets: 0
end

defmodule HT.Repo do
  use GenServer
  import Ecto.Changeset

  def start_link(db_folder) do
    state =
      for schema <- schemas(), into: %{} do
        fname = Path.join(db_folder, [to_string(schema), ".dets"])

        {:ok, handle} =
          :dets.open_file(String.to_atom(fname), file: to_charlist(fname), type: :set)

        {schema, handle}
      end

    GenServer.start_link(__MODULE__, state, name: HTRepo)
  end

  def init(state) do
    {:ok, state}
  end

  def all(thing) do
    GenServer.call(HTRepo, {:all, thing})
  end

  def delete(thing) do
    GenServer.call(HTRepo, {:delete, thing})
  end

  def get!(thing) when is_struct(thing) do
    GenServer.call(HTRepo, {:get, thing})
  end

  def get!(thing, id) when is_atom(thing) do
    GenServer.call(HTRepo, {:get, struct(thing, %{id: id})})
  end

  def insert(%_type{} = thing) when is_struct(thing) do
    GenServer.call(HTRepo, {:insert, thing})
  end

  def migrate(thing, callback) when is_struct(thing) do
    GenServer.call(HTRepo, {:migrate, thing, callback})
  end

  def pids() do
    GenServer.call(HTRepo, :pids)
  end

  def select(%_type{} = query) when is_struct(query) do
    GenServer.call(HTRepo, {:select, query})
  end

  def update(%_type{} = query) when is_struct(query) do
    GenServer.call(HTRepo, {:update, query})
  end

  # IMPLEMENTATION

  def handle_call({:all, type}, _from, state) when is_atom(type) do
    handle = Map.get(state, type)
    data2 = fetch_all(type, handle)
    {:reply, data2, state}
  end

  def handle_call({:all, %type{} = thing}, from, state) do
    handle_call({:all, type}, from, state)
  end

  def handle_call({:delete, %type{id: id} = thing}, _from, state) do
    handle = Map.get(state, type)
    delete_id(type, handle, id)
    {:reply, :ok, state}
  end

  def handle_call({:get, %type{} = thing}, _from, state) do
    handle = Map.get(state, type)
    id = Map.get(thing, :id)
    data = get_by_id!(type, handle, id)
    {:reply, data, state}
  end

  def handle_call({:migrate, %type{}, callback}, _from, state) when is_function(callback) do
    handle = Map.get(state, type)
    items = fetch_all(type, handle)
    updates = Enum.map(items, &callback.(&1, type)) |> Util.except([%{}, nil])
    log = Enum.each(updates, &update_with_changeset(&1, state))
    {:reply, log, state}
  end

  def handle_call({:insert, %Ecto.Changeset{valid?: true} = changeset}, _from, state) do
    with %type{} = value = changeset.data do
      v2 =
        value
        |> unnil(:id, &uuid/0)
        |> unnil(:inserted_at, &DateTime.utc_now/0)
        |> unnil(:updated_at, &DateTime.utc_now/0)
        |> Map.drop([:__meta__, :__schema__, :__struct__])
        |> Map.merge(changeset.changes)

      id = Map.get(v2, :id)
      handle = Map.get(state, type)
      item = {id, v2}
      IO.inspect(item, label: :insert)

      case :dets.insert(handle, item) do
        :ok -> {:reply, {:ok, item}, state}
        other -> {:reply, {:error, other}, state}
      end
    end
  end

  def handle_call(:pids, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:select, query}, _from, state) do
    {:reply, query, state}
  end

  def handle_call({:update, %Ecto.Changeset{valid?: true} = changeset}, _from, state) do
    data2 = update_with_changeset(changeset, state)
    {:reply, {:ok, data2}, state}
  end

  # HELPERS

  defp delete_id(type, handle, id) do
    :ok = :dets.delete(handle, id)
  end

  defp fetch_all(type, handle) do
    data = :dets.match(handle, :"$1")
    data2 = Enum.map(data, fn x -> make_row(x, type) end)
  end

  defp get_by_id!(type, handle, id) do
    data =
      case :dets.match(handle, {id, :"$1"}) do
        [] ->
          nil

        other ->
          record =
            other
            |> hd
            |> hd
            |> Map.put(:id, id)

          struct(type, record)
      end
  end

  defp make_row([{id, row}], type) when is_map(row) do
    make_row({id, row}, type)
  end

  defp make_row({id, row}, type) when is_map(row) do
    struct(type, row |> Map.put(:id, id))
  end

  defp schemas() do
    {:ok, modules} = :application.get_key(:hairytext, :modules)

    modules
    |> Enum.filter(&({:__schema__, 1} in &1.__info__(:functions)))
  end

  defp update_with_changeset(%Ecto.Changeset{} = changeset, state) do
    with %type{} = query = changeset.data do
      handle = Map.get(state, type)
      id = Map.get(query, :id)

      data =
        get_by_id!(type, handle, id)
        |> Map.put(:updated_at, DateTime.utc_now())

      data2 =
        Enum.reduce(changeset.changes, data, fn {k, v}, acc ->
          Map.put(acc, k, v)
        end)

      data3 = data2 |> Map.drop([:__meta__, :__schema__, :__struct__])
      :ok = :dets.insert(handle, {id, data3})
    end
  end

  defp uuid() do
    Ecto.UUID.generate()
  end

  defp unnil(map, key, new_val_fun) do
    if not Map.has_key?(map, key) or Map.get(map, key) == nil do
      Map.put(map, key, new_val_fun.())
    else
      map
    end
  end
end
