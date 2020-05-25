defmodule HTWeb.TrainLive do
  use HTWeb, :live_view
  alias HT.Data
  alias HT.Data.Example

  @impl true
  def mount(_params, session, socket) do
		# IO.inspect({params, session}, label: TrainLive_mount)
    ex2 = Data.list_examples_for_project(session["cur_project"].id)
    {labels, entities} = Util.label_stats_for_examples(ex2)
    s2=socket 
      |> HTWeb.SessionSetup.assigns(session) 
      |> assign(:n_examples, length(ex2))
      |> assign(:all_labels, labels)
      |> assign(:all_entities, entities)
      |> assign(:log, [])
    {:ok, s2} 
  end

  @impl true
  def handle_params(params, url, socket) do
		# IO.inspect({params, url}, label: ExampleLive_handle_params)
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(msg, socket) do
    data = elem(msg, 1)
    {:noreply, socket |> assign(:log, [Jason.decode!(data) | Util.take(socket.assigns.log, 25)])}
  end

  def handle_event("train", params, socket) do
    IO.inspect(params, label: :train_event)
    cp = socket.assigns.cur_project
    examples = HT.Data.list_examples_for_project(cp.id)
      |> Enum.filter(&(&1.label != nil and Util.head(&1.label) != "_"))
    labels = Util.pluck(examples, :label)
    epochs = 10
    out = if cp.project_type == "text" do
      HT.Spacy.train(epochs, cp, examples, labels, self(), cp.id)
    else
      HT.ImageNet.train(epochs, cp, examples, labels, self(), cp.id)
    end
    IO.inspect(out, label: :train_go)
		{:noreply, assign(socket, log: [])}
  end

  defp apply_action(socket, action, params) do
    IO.inspect({action,params}, label: TrainLive_apply_action)
    socket
  end

  @impl true
  def render(assigns) do
    # XXX pass in # of epochs from UI or model config tool! THIS IS MADNESS!
    ~L"""

    <h1>Training</h1>

    <p>
      <label for="epochs">Training epochs:</label>
      <select name="epochs" id="epochs">
        <option value="10">10</option>
        <option value="100">100</option>
        <option value="500">500</option>
        <option value="1000">1000</option>
      </select>
      <a class="button" phx-click="train" phx-value-epochs="#epochs" phx-disable-with="Training..">Train</a>
    </p>
    
    <%= if @log != [] do %>
      <h3>Training status</h3>

      <%= if @cur_project.project_type == "text" do %>
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
      <% else %>
        <%= for x <- @log do %> 
          <p><%= Jason.encode!(x) %></p>
        <% end %>
      <% end %>
    <% end %>

    <div class="ct-chart ct-perfect-fourth"></div>
    <script>
    var data = {
      labels: <%= raw Jason.encode!(Map.keys(@all_labels) |> Enum.map(&String.slice(&1,0,4))) %>,
      series: [ <%= raw Jason.encode!(Map.values(@all_labels)) %> ]
    }
    var sum = function(a,b) { return a+b; }
    var opts = {
    }
    var pi = new Chartist.Bar('.ct-chart', data, opts);
    setTimeout(function() { pi.update() }, 400)
    </script>

    <p>
      Total examples: <b><%= @n_examples %></b>
    </p>
    <p>
      Labels in use: 
      <%= for {label, count} <- @all_labels do %>
        <%= if label != nil do %> 
          <a href="<%= Routes.example_index_path(@socket, :index, label: label) %>"><%= label %> (<%= count %> examples)</a> 
        <% else %>
          <a href="<%= Routes.example_index_path(@socket, :index, label: "_") %>">UNLABELED (<%= count %> examples)</a> 
        <% end %>
      <% end %>
    </p>
    <p>
      Entities in use: 
      <%= for {entity, count} <- @all_entities do %>
        <%= if entity != nil and entity != %{} do %> 
          <a href="<%= Routes.example_index_path(@socket, :entity, entity) %>"><%= entity %> (<%= count %> examples)</a> 
        <% end %>
      <% end %>
    </p>
    """
  end
end
