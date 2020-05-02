defmodule HTWeb.ExampleLive.FormComponent do
  use HTWeb, :live_component

  alias HT.Data

  def mount(params, session, socket) do
		IO.inspect({params, session}, label: ExampleLive_form_mount)
		{:ok, socket}
	end

  @impl true
  def update(%{example: example} = assigns, socket) do
		IO.inspect({assigns}, label: :ExampleLiveForm_update)
    changeset = Data.change_example(example) # struct(HT.Data.Example, example))
    examples = Data.list_examples()
    labels = Util.pluck(examples, :label) |> Enum.uniq()
    entities = Util.pluck(examples, :entities) |> Enum.flat_map(&Map.values/1) |> Enum.uniq()
    s2 = socket |> assign(:all_labels, labels) |> assign(:all_entities, entities) 
    {:ok,
     s2
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("del_entity", params, socket) do
		IO.inspect(params, label: :del_entity)
		example = HT.Data.get_example!(socket.assigns.example.id)
		example2 = Map.update! example, :entities, fn x -> Map.delete(x, params["item"]) end
		IO.inspect(example2, label: :after_del_entities)
    {:ok, _new} = Data.update_example(socket.assigns.example, %{"entities" => example2.entities})
    #example = Data.get_example!(id)
    #{:ok, _} = Data.delete_example(example)
		{:noreply, assign(socket, example: example2)}
  end
	
  @impl true
  def handle_event("validate", %{"example" => example_params}, socket) do
    changeset =
      # struct(HT.Data.Example, socket.assigns.example)
      socket.assigns.example
      |> Data.change_example(example_params)
      |> Map.put(:action, :validate)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"example" => example_params} = params, socket) do
    IO.inspect(params, label: :event_save)
    assigns = socket.assigns
    IO.inspect(assigns, label: :event_save_assigns)
    p2 = case Map.has_key? example_params, "entlabels" do
      true -> example_params |> Map.put "entities", make_entities(example_params)
      false -> example_params |> Map.put "entities", %{}
    end
      |> Map.put "project", (if Map.has_key?(assigns, :project) do assigns.project else "" end)
    IO.inspect(p2, label: :p2)
    save_example(socket, socket.assigns.action, p2)
  end

  defp save_example(socket, :edit, example_params) do
    case Data.update_example(socket.assigns.example, example_params) do
      {:ok, _example} ->
        {:noreply,
         socket
         |> put_flash(:info, "Example updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}
      {:error, %{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_example(socket, :new, example_params) do
    IO.inspect(example_params, label: :form_component_new)
    case Data.create_example(example_params) do
      {:ok, _example} ->
        {:noreply,
         socket
         |> put_flash(:info, "Example created successfully")
         |> push_redirect(to: socket.assigns.return_to)}
      {:error, %{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_example(socket, :new_with_text, example_params) do
    IO.inspect(example_params, label: :form_component_new_with_text)
    case Data.create_example(example_params) do
      {:ok, _example} ->
        {:noreply,
         socket
         |> put_flash(:info, "Example created successfully")
         |> push_redirect(to: socket.assigns.return_to)}
      {:error, %{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp make_entities(params) do
      ents = for {txt, lbl} <- Enum.zip(params["enttext"], params["entlabels"]) do
        txt2 = String.trim(txt)
        if Util.has(params["text"], txt2), do: {txt2, lbl}, else: {}
      end 
      e2 = ents
        |> Enum.filter fn x -> x != {} end

      IO.inspect(e2, label: :make_entities)
      e3 = Util.map e2
      IO.inspect(e3, label: :make_entities)
  end
end
