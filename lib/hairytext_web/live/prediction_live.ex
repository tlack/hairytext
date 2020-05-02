defmodule HTWeb.PredictionLive do
  use HTWeb, :live_view

  alias HT.Data
  alias HT.Data.Example

  @impl true
  def mount(params, session, socket) do
		IO.inspect({params, session}, label: PredictionLive_mount)
    {:ok, 
			socket 
			|> assign(:query, "")
      |> assign(:sort, "date")
		}
  end

  @impl true
  def handle_params(params, url, socket) do
		IO.inspect({params, url}, label: PredictionLive_handle_params)
    {:noreply, view(socket, params)}
  end

  def view(socket, _params) do
    preds = Data.list_predictions()
    socket |> assign(:predictions, preds)
  end

  @impl true
  def render(assigns) do
    ~L"""

    <h1>Predictions (by <%= @sort %>)</h1>

    <p>
      Sort by:
      <%= live_patch "Recent", to: Routes.prediction_path(@socket, :index, sort: :date), class: "button" %></span>
      <%= live_patch "Confidence", to: Routes.prediction_path(@socket, :index, sort: :confidence), class: "button" %></span>
    </p>
    
    <%= for pred <- @predictions do %>
      <%= live_component @socket, PredictionComponent, prediction: pred %>
    <% end %>
    """
  end
end

