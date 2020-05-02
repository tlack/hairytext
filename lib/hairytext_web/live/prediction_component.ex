defmodule HTWeb.PredictionComponent do
  use HTWeb, :live_component

  @impl true
  def render(assigns) do
    IO.inspect(assigns, label: PredictionComponent_render)
    p2 = Util.from_spacy_prediction(assigns.prediction)

    ~L"""
    <div class="prediction">
      <%= if p2.text do %>
        <p><%= Util.entity_marked_example_text(p2) %></p>
      <% end %>
      <div class="details">
        <span>
          <b>Label:</b> <%= p2.label %>
          (<%= Util.fmt_pct(p2.label_confidence) %>)
          </span>
        <span>
          <b>Entities:</b> <%= if p2.entities do length(Map.keys(p2.entities)) else 0 end %>
        </span>
        <%= live_redirect "Label", to: Routes.example_index_path(@socket, :new_with_text, p2.text), class: "button" %></span>
      </div>
    </div>
    """
  end
end

