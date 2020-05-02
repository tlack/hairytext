defmodule HTWeb.TrainLive do
  use HTWeb, :live_view
  alias HT.Data
  alias HT.Data.Example

  @impl true
  def mount(params, session, socket) do
		IO.inspect({params, session}, label: TrainLive_mount)
    {:ok, socket |> assign(:log, [])} 
  end

  @impl true
  def handle_params(params, url, socket) do
		IO.inspect({params, url}, label: ExampleLive_handle_params)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_info({'loss', data}, socket) do
    {:noreply, socket |> assign(:log, [Jason.decode!(data) | Util.take(socket.assigns.log, 25)])}
  end

  defp apply_action(socket, :go, params) do
    examples = HT.Data.list_examples
    labels = Util.pluck(examples, :label)
    accuracy = Spacy.train(examples, labels, self)
    socket |> assign(:log, [])
  end

  defp apply_action(socket, action, params) do
    IO.inspect({action,params}, label: TrainLive_apply_action)
    socket
  end

  def render(assigns) do
    ~L"""

    <h1>Training</h1>

    <p>
      <%= live_patch "Start", to: Routes.train_path(@socket, :go), class: "button" %></span>
    </p>
    
    <%= if @log != [] do %>
      <h3>Training status</h3>
      <table>
      <thead>
      <tr>
        <th>Epoch</th>
        <th>NER Loss</th>
        <th>Classifier Loss</th>
      </tr>
      </thead>
      <%= for x <- @log do %> 
      <tr>
        <td><%= x["epoch"] %></td>
        <td><%= x["ner"] %></td>
        <td><%= Util.fmt_pct x["textcat"] %></td>
      </tr>
      <% end %>
      </table>
    <% end %>
    """
  end
end
