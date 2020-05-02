defmodule HTWeb.ExampleLive.Show do
  use HTWeb, :live_view

  alias HT.Data

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:example, Data.get_example!(id))}
  end

  defp page_title(:show), do: "Show Example"
  defp page_title(:edit), do: "Edit Example"
end
