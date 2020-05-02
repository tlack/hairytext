defmodule Spacy do
  use GenServer
  alias HT.Data.Example

  def start_link({python, path}) do
    GenServer.start_link(__MODULE__, {python, path}, name: Spacy)
  end

  def predict(text) do
    GenServer.call(Spacy, {:predict, text})
  end

  def train(examples, allowed_labels, clientpid) do
    GenServer.cast(Spacy, {:train, examples, allowed_labels, clientpid})
  end

  # Implementation:

  def init({python, path}) do
    IO.inspect(:Spacy_init)
    :python.start([{:python, to_charlist(python)}, {:python_path, to_charlist(path)}])
  end

  def handle_call({:predict, text}, from, pid) do
    IO.inspect({:predict, text, from, pid}, label: :predict)
    {:reply, :python.call(pid, :hairytext, :predict, [text]), pid}
  end

  defp make_cats(%Example{label: ""} = _row), do: ""
  defp make_cats(%Example{label: nil} = _row), do: ""
  defp make_cats(%Example{label: label} = _row), do: label

  defp make_ents(%Example{entities: nil} = _row), do: %{}
  defp make_ents(%Example{entities: ""} = _row), do: %{}

  defp make_ents(%Example{} = row) do
    Enum.map(row.entities, fn {k, v} ->
      IO.inspect({row.text, k, v})

      case :binary.match(row.text, k) do
        {pos, len} ->
          {pos, pos + len, v}

        :nomatch ->
          nil
      end
    end)
  end

  defp make_spacy_row(%Example{} = row) do
    ents = make_ents(row) |> List.to_tuple()
    cats = make_cats(row)
    {row.text, {ents, cats}}
  end

  defp make_spacy_row(text) when is_binary(text) do
    {text, {[], ''}}
  end

  def handle_cast({:train, examples, allowed_labels, clientpid}, pid)
      when is_list(examples) and is_list(allowed_labels) do
    e2 =
      Enum.filter(examples, fn x -> Util.has(allowed_labels, x.label) end)
      |> Enum.map(&make_spacy_row/1)

    {:noreply, :python.call(pid, :hairytext, :train, [clientpid, e2]), pid}
  end
end
