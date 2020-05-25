defmodule HTWeb.ExampleLive.Index do
  use HTWeb, :live_view

  alias HT.Data
  alias HT.Data.Example

  @impl true
  def mount(params, session, socket) do
    {:ok, 
			socket 
      |> HTWeb.SessionSetup.assigns(session)
			|> assign(:query, "")
		}
  end

  @impl true
  def handle_params(params, url, socket) do
    s2 = socket |> assign(:filter, params["filter"] || %{}) 
    {:noreply, apply_action(s2, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :delete, %{"id" => id}) do
    example = Data.get_example!(id)
    case example do
      nil -> nil    # already deleted
      _other -> :ok = Data.delete_example(example)
    end
    socket
    |> push_redirect(to: Routes.example_index_path(socket, :index, [filter: socket.assigns.filter]))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "Examples")
    |> assign(:example, Data.get_example!(id))
  end

  defp apply_action(socket, :new, params) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "Examples")
    |> assign(:example, %Example{project: socket.assigns.cur_project_id})
  end

  defp apply_action(socket, :new_with_text, params) do
    socket
    |> assign_metadata()
    |> assign(:back_to, params["back_to"])
    |> assign(:page_title, "Examples")
    |> assign(:example, %Example{
        text: params["text"], 
        project: socket.assigns.cur_project_id})
  end

  defp apply_action(socket, :index, %{"filter" => %{"label" => label}}) do
    txt = if label == "_", do: "unlabeled", else: "labeled #{label}"
    s2 = socket |> assign_metadata()
    s2 |> assign(:page_title, "Examples (#{txt}, #{length(s2.assigns.results)})")
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "#{socket.assigns.cur_project.name} Examples")
  end

  defp apply_action(socket, :entity, %{"entity" => entity}) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "Examples (with entity \"#{entity}\")")
  end

  defp apply_action(socket, :delentity, _params) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "Listing Examples")
    |> assign(:example, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    example = Data.get_example!(id)
    {:ok, _} = Data.delete_example(example)
    {:noreply, assign_metadata(socket) |> assign(:live_action, :index)}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
		IO.inspect(query, label: :handle_event_suggest)
    if Util.len(query) > 2 do 
      results = search(socket, query) 
      {:noreply, assign(socket, results: results, query: query)}
    else
      {:noreply, socket}
    end
  end

	def handle_event("selected", %{"text" => text}, socket) do
		IO.inspect({text,socket}, label: :selected)
		example = HT.Data.get_example!(socket.assigns.example.id)
		example2 = Map.update example, :entities, %{}, fn x -> Map.put(x || %{}, text, "unlabeled") end
		# require IEx; IEx.pry
		{:noreply, assign(socket, example: example2)}
	end

  defp assign_metadata(socket) do
    {{labels, entities}, results, n_examples} = fetch_filtered_examples(socket, socket.assigns.filter)
    socket 
      |> assign(:results, results)
      |> assign(:all_labels, labels) 
      |> assign(:all_entities, entities) 
      |> assign(:n_examples, n_examples)
      |> assign_new(:results, fn -> [] end) 
      |> assign_new(:example, fn -> nil end)
  end

	defp search(socket, query) do
    fetch_filtered_examples(socket, %{})
      |> Enum.filter(fn x -> if x.text, do: x.text =~ query, else: false  end)
	end

  defp filter_examples(socket, {"label", label}, examples) do
    search = if label == "_", do: nil, else: label
    examples |> Enum.filter(& &1.label==search)
  end

  defp filter_examples(socket, {"entity", entity}, examples) do
    examples |> Enum.filter(fn x -> x.entities != nil and entity in Map.values(x.entities) end)
  end

  defp fetch_filtered_examples(socket, filter) do
    examples = Data.list_examples_for_project(socket.assigns.cur_project_id)
    stats = Util.label_stats_for_examples(examples)
    out = Enum.reduce(filter, examples, fn fkv, exacc -> filter_examples(socket, fkv, exacc) end)
    {stats, out, length(examples)}
  end
end
