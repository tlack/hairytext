defmodule HTWeb.APIController do
  use HTWeb, :controller

  def predict(conn, %{"text" => text} = params) do
    IO.inspect(params, label: :APIController_predict)
    result = HT.Spacy.predict(text)
    pred = Util.from_spacy_prediction(result)
    HT.Data.create_prediction(pred)
    json(conn, pred)
  end

  def export_project(conn, %{"id" => project_id} = _params) do
    proj = HT.Data.get_project!(project_id)
    raw_examples = HT.Data.list_examples_for_project(proj.id)
    examples = raw_examples |> Util.maps() |> Jason.encode!()
    predictions = HT.Data.list_predictions() |> Util.maps() |> Jason.encode!()
    fname = (proj.name |> String.replace(~r"[^a-z0-9]"i, "_")) <> Util.ugly_datetime()

    chunker =
      conn
      |> put_resp_header("content-disposition", ~s(attachment; filename="#{fname}.zip"))
      |> put_resp_content_type("content-type", "application/zip")
      |> send_chunked(200)

    common = [
      Zstream.entry("examples.json", [examples]), Zstream.entry("predictions.json", [predictions])
    ]

    z = if proj.project_type == "image" do
      image_dir = Application.fetch_env!(:hairytext, HT.ImageNet)[:image_dir]
      abs_image_dir = Path.expand(image_dir)
      medias = Enum.map(raw_examples, fn x ->
        data = File.read!(Path.join([abs_image_dir, proj.id, x.image]))
        Zstream.entry("images/#{x.image}", [data])
      end)
      Zstream.zip(common ++ medias)
    else
      Zstream.zip(common)
    end

    z
    |> Stream.into(chunker)
    |> Stream.run()

    chunker
  end
end
