defmodule HT.ImageNet do
  use GenServer
  alias HT.Data.Example

  def start_link({python, path}) do
    GenServer.start_link(__MODULE__, {python, path}, name: ImageNet)
  end

  def predict(text) do
    GenServer.call(ImageNet, {:predict, text})
  end

  def train(examples, allowed_labels, clientpid, project_id) do
    GenServer.cast(ImageNet, {:train, examples, allowed_labels, clientpid, project_id})
  end

  # Implementation:

  def init({python, path}) do
    IO.inspect(:ImageNet_init)
    :python.start([{:python, to_charlist(python)}, {:python_path, to_charlist(path)}])
  end

  def handle_call({:predict, image}, from, pid) do
    IO.inspect({:predict, image, from, pid}, label: :ImageNet_predict)
    {:reply, :python.call(pid, :hairyimage, :predict, [image]), pid}
  end

  def handle_cast({:train, examples, labels, clientpid, project_id}, pid) do
    image_dir = Path.expand Application.fetch_env!(:hairytext, HT.ImageNet)[:image_dir] |> Path.join project_id
    IO.inspect({image_dir, labels, pid}, label: :ImageNet_train)
    ex2 = examples |> Enum.filter(& &1.label != nil) |> Enum.map &{&1.image, &1.label}
    IO.inspect(ex2, label: :ImageNet_train_ex2)
    {:noreply, :python.call(pid, :hairyimage, :train, [clientpid, image_dir, ex2]), pid}
  end
end
