defmodule HTWeb.ExampleLive.Index do
  use HTWeb, :live_view

  alias HT.Data
  alias HT.Data.Example

  @impl true
  def mount(params, session, socket) do
		IO.inspect({params, session}, label: ExampleLive_mount)
    {:ok, 
			socket 
			|> assign(:query, "")
		}
  end

  @impl true
  def handle_params(params, url, socket) do
		IO.inspect({params, url}, label: ExampleLive_handle_params)
    s2 = socket |> assign(:my_url, url)
    {:noreply, apply_action(s2, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "Edit Example")
    |> assign(:example, Data.get_example!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign_metadata()
    |> assign(:page_title, "New Example")
    |> assign(:example, %Example{})
  end

  defp apply_action(socket, :new_with_text, params) do
    IO.inspect(params, label: :examplelive_new_with_text)
    socket
    |> assign_metadata()
    |> assign(:page_title, "New Example")
    |> assign(:example, %Example{text: params["text"]})
  end

  defp apply_action(socket, :index, _params) do
    IO.inspect(:index)
    examples = fetch_examples()
    labels = Util.pluck(examples, :label)
    socket
    |> assign_metadata()
    |> assign(:page_title, "Listing Examples")
    |> assign(:results, examples)
    |> assign(:all_labels, labels)
    |> assign(:example, nil)
  end

  defp apply_action(socket, :project, %{"project" => pid}) do
    proj = Data.get_project!(pid)
    examples = fetch_examples()
    ex2 = examples |> Enum.filter fn x -> x.project == pid end
    socket
    |> assign(:results, ex2)
    |> assign(:project, proj.id)
    |> assign(:page_title, "#{proj.name} Examples")
    |> assign_metadata()
  end

  defp apply_action(socket, :label, %{"label" => label}) do
    examples = fetch_examples()
    ex2 = examples |> Enum.filter fn x -> x.label == label end
    socket
    |> assign_metadata()
    |> assign(:results, ex2)
    |> assign(:page_title, "\"#{label}\" Examples")
  end

  defp apply_action(socket, :entity, %{"entity" => entity}) do
    examples = fetch_examples()
    ex2 = examples |> Enum.filter fn x -> x.entities != nil and entity in Map.values(x.entities) end
    socket
    |> assign_metadata()
    |> assign(:results, ex2)
    |> assign(:page_title, "\"#{entity}\" Examples")
  end

  defp apply_action(socket, :delentity, _params) do
    socket
    |> assign(:page_title, "Listing Examples")
    |> assign(:example, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    example = Data.get_example!(id)
    {:ok, _} = Data.delete_example(example)
    {:noreply, assign(socket, :examples, fetch_examples())}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
		IO.inspect(query, label: :handle_event_suggest)
		results = search(query) 
			|> Enum.filter(fn x -> x.text =~ query end)
    {:noreply, assign(socket, results: results, query: query)}
  end

	def handle_event("selected", %{"text" => text}, socket) do
		IO.inspect({text,socket}, label: :selected)
		example = HT.Data.get_example!(socket.assigns.example.id)
		example2 = Map.update! example, :entities, fn x -> Map.put(x || %{}, text, "unlabeled") end
		# require IEx; IEx.pry
		{:noreply, assign(socket, example: example2)}
	end

  defp assign_metadata(socket) do
    examples = fetch_examples()
    labels = Util.pluck(examples, :label)
    entities = Util.pluck(examples, :entities) |> Enum.flat_map &Map.values/1 
    socket |> assign(:all_labels, labels) |> assign(:all_entities, entities) |> assign(:results, []) |> assign(:example, nil)
  end

	defp search(query) do
		Data.list_examples() 
	end
  defp fetch_examples do
    Data.list_examples()
  end
end
