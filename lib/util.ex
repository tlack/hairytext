defmodule Util do

  def argmax(map) when is_map(map) do
    k = Map.keys(map)
    v = Map.values(map)
    mx = Enum.max(v)
    mi = Enum.find_index(v, fn x -> x == mx end)
    Enum.at(k, mi)
  end

  def except(struc, keys) when is_struct(struc) and is_list(keys) do
    :nyi
  end
  def except(map, keys) when is_map(map) and is_list(keys) do
    :nyi
  end
  def except(list, elems) when is_list(list) and is_list(elems) do
    Enum.filter(list, fn x -> !has(elems, x) end)
  end
  def except(list, elem) when is_list(list) and not is_list(elem) do
    Enum.filter(list, fn x -> x != elem end)
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

  def friendly_hash(str), do: String.slice(str, 0, 5)

  def head(list) when is_list(list), do: hd(list)
  def head(str)  when is_binary(str), do: String.slice(str, 0, 1) # XXX better way?

  def len(str) when is_binary(str), do: String.length(str)
  def len(list) when is_list(list), do: length(list)

  def map(keys, vals) when is_list(keys) and is_list(vals) do
    # Enum.zip(keys,vals) doesnt create a map when the keys are strings
    # but does when they are atoms
    Enum.zip(keys, vals) |> Enum.into(%{})
  end
  def map(a_struct) when is_struct(a_struct) do
      Map.from_struct(a_struct) |> Map.drop([:__meta__, :__schema__, :__struct__])
  end
  def map(kv_pairs) when is_list(kv_pairs) and is_tuple(hd(kv_pairs)) do
    IO.inspect(kv_pairs, label: :Util_map)
    if kv_pairs == [{}], do: %{}, else: Enum.into(kv_pairs |> Enum.filter(&(&1!={})), %{})
  end
  def map([]), do: %{}
  def map([{}]), do: %{}

  def maps([]), do: []
  def maps(list) when is_list(list) and is_struct(hd(list)), do: Enum.map(list, &map/1)

  def map_to_keywords(map) when is_map(map) do
    Enum.map(map, fn({key, value}) -> {String.to_existing_atom(key), value} end)
  end

  def pluck([], _key), do: []
  def pluck(list, key) when is_list(list) and is_map(hd(list)) do
    Enum.map list, fn x -> Map.get(x, key) end
  end

  def take(str, n) when is_binary(str), do: String.slice(str, 0, n)
  def take(list, n), do: Enum.take(list, n)

  # More utility style stuff:

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

  def example_image_url(example), do: "/image_examples/#{example.project}/#{example.image}"

  def image_dir_for_project(project_id) do
    image_dir =
      Path.expand(
        Application.fetch_env!(:hairytext, HT.ImageNet)[:image_dir]
        |> Path.join(project_id)
      )
  end

  def expand_image_str_to_fname(project_id, %Plug.Upload{} = upload) do
    fname = ugly_datetime() <> upload.filename
    image_dir = image_dir_for_project(project_id)
    full_fname = Path.join(image_dir, fname)
    File.write!(full_fname, File.read!(upload.path))
    fname
  end

  def expand_image_str_to_fname(project_id, str) do
    if Regex.match?(~r"^https?://", str) do
      {:ok, response} = HTTPoison.get(str, [], hackney: [:insecure])
      headers = map(response.headers)
      ext = case headers["Content-Type"] do
        "image/jpeg" -> ".jpg"
        "image/png" -> ".png"
        _other -> ""
      end
      
      if ext != "" do
        fname = make_url_fname(str) <> ext
        image_dir = image_dir_for_project(project_id)
        full_fname = Path.join(image_dir, fname)
        File.write!(full_fname, response.body)
        fname
      else
        nil
      end
    else
      if String.length(str) > 128 do
        fname = ugly_datetime() <> ".jpg"
        image_dir = image_dir_for_project(project_id)
        full_fname = Path.join(image_dir, fname)
        File.write!(full_fname, str)
        fname
      else
        str
      end
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

  def label_stats_for_examples(ex) do
    labels = pluck(ex, :label) |> Enum.frequencies
    ents = pluck(ex, :entities) |> Enum.filter(& &1 == %{}) |> Enum.frequencies
    {labels, ents}
  end

  def make_url_fname(url) do
    Regex.replace(~r/[^a-z0-9]/iu, url, "")
  end

  def project_labels_and_entities(cp) do
    labels = if cp.labels, do: String.split(cp.labels, ","), else: []
    entities = if cp.entities, do: String.split(cp.entities, ","), else: []
    {labels, entities}
  end

  def ugly_datetime(), do: DateTime.utc_now() |> DateTime.to_iso8601(:basic)

  def upsert_examples_from_image_folder() do
    image_dir = Application.fetch_env!(:hairytext, HT.ImageNet)[:image_dir]
    abs_image_dir = Path.expand(image_dir)
    fnames = Path.wildcard("#{abs_image_dir}/**/*.{jpg,png}")
      |> Enum.map &String.replace(&1, abs_image_dir, "")
    examples_by_proj = HT.Data.list_examples() 
      |> Enum.filter(& &1.image)
      |> Enum.group_by(& &1.project)
    Enum.map(fnames, fn x -> 
      [_, proj, fname] = Path.split(x)
      proj_imgs = Map.get(examples_by_proj, proj) |> pluck(:image)
      
      case Enum.find(proj_imgs, & &1==fname) do
        nil -> 
          ex = %{"image" => fname, "project" => proj}
          IO.inspect(ex, label: :new_example)
          out = HT.Data.create_example(ex)
        _ ->
          IO.inspect({:skipped, fname})
      end
    end)
    IO.inspect(fnames)
    IO.inspect(examples_by_proj)
  end
end

