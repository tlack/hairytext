defmodule Util do

  def argmax(map) when is_map(map) do
    k = Map.keys(map)
    v = Map.values(map)
    mx = Enum.max(v)
    mi = Enum.find_index(v, fn x -> x == mx end)
    Enum.at(k, mi)
  end

  def fmt_pct(flt) when is_float(flt), do: ((round(flt * 10000) / 100) |> to_string()) <> "%"

  def has(map, key) when is_map(map), do: Map.has_key?(map, key)
  def has(list, value) when is_list(list), do: Enum.member? list, value
  def has(str, substr) when is_binary(str) and is_binary(substr) do
    case :binary.match(str, substr) do
      {_s, _e} -> true
      :nomatch -> false
    end
  end

  def key(map) when is_map(map), do: Map.keys(map)
  def key(list) when is_list(list), do: Range.new(0, length(list))

  def map(keys, vals) when is_list(keys) and is_list(vals) do
    # Enum.zip(keys,vals) doesnt create a map when the keys are strings
    # but does when they are atoms
    Enum.zip(keys, vals) |> Enum.into(%{})
  end
  def map(kv_pairs) when is_list(kv_pairs) and is_tuple(hd(kv_pairs)) do
    IO.inspect(kv_pairs, label: :Util_map)
    if kv_pairs == [{}], do: %{}, else: Enum.into(kv_pairs |> Enum.filter(&(&1!={})), %{})
  end
  def map([]), do: %{}
  def map([{}]), do: %{}

  def pluck([], _key), do: []
  def pluck(list, key) when is_list(list) and is_map(hd(list)) do
    Enum.map list, fn x -> Map.get(x, key) end
  end

  def take(str, n) when is_binary(str), do: String.slice(str, 0, n)
  def take(list, n), do: Enum.take(list, n)

  def entity_marked_example_text(%HT.Data.Prediction{} = data) do
    IO.inspect(data, label: :entity_marked_example_text)
    text = data.text
    case data.entities do
      %{} ->
        Enum.reduce(data.entities, data.text, fn {text,type}, acc -> 
            acc |> String.replace(text, "<span class=ent>#{text}<span>#{type}</span></span>") 
          end) |> Phoenix.HTML.raw
      _other ->
        text
    end
  end

  def entity_marked_example_text(%HT.Data.Example{} = data) do
    text = data.text
    case data.entities do
      %{} ->
        Enum.reduce(data.entities, data.text, fn {text,type}, acc -> 
            acc |> String.replace(text, "<span class=ent>#{text}<span>#{type}</span></span>") 
          end) |> Phoenix.HTML.raw
      _other ->
        text
    end
  end

  def from_spacy_prediction(%HT.Data.Prediction{} = pred), do: pred

  def from_spacy_prediction(result) do
    cls = result['classification']
    classification = Util.argmax(cls)
    ents = Enum.map(result['entities'], fn [x,y] -> {y,x} end) |> Enum.into(%{})
    # pred = %{"text" => to_string(result['text']), "label" => to_string(classification), "label_confidence" => cls[classification], "entities" => ents}
    pred = %HT.Data.Prediction{text: to_string(result['text']), label: to_string(classification), label_confidence: cls[classification], entities: ents}
  end

end


