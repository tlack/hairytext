defmodule HTWeb.APIController do
  use HTWeb, :controller

  def predict(conn, %{"text" => text} = params) do
    IO.inspect(params, label: :APIController_predict)
    result = Spacy.predict(text)
    pred = Util.from_spacy_prediction(result)
    HT.Data.create_prediction pred
    json conn, pred
  end

end
