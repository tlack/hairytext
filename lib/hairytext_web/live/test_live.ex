defmodule HTWeb.TestLive do
  use HTWeb, :live_view
  alias HT.Data
  alias HT.Data.Example

  @impl true
  def mount(params, session, socket) do
		IO.inspect({params, session}, label: TestLive_mount)
    {:ok, socket |> assign(:query, "") |> assign(:prediction, nil)}
  end

  @impl true
  def handle_params(params, url, socket) do
		IO.inspect({params, url}, label: TestLive_handle_params)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, action, params) do
    IO.inspect({action,params}, label: TrainLive_apply_action)
    socket
  end

  @impl true
  def handle_event("predict", %{"q" => query}, socket) do
    p = HT.Spacy.predict(query)
    {:noreply, assign(socket, prediction: p, query: query)}
  end

  def render(assigns) do
    IO.inspect(assigns, label: :render)
    ~L"""

    <h1>Test</h1>
    <form phx-change="predict">
      <input type="text" name="q" id="q" value="<%= @query %>" placeholder="Enter text to classify" 
        autocomplete="off" phx-debounce=2500 />
      <%= if @prediction do %>
        <div class="predictions">
          <%= live_component @socket, HTWeb.PredictionComponent, prediction: @prediction %>
        </div>
      <% end %>
    </form>
    """
  end
end
