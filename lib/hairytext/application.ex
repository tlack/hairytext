defmodule HT.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HTWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HT.PubSub},
      # Start the Endpoint (http/https)
      HTWeb.Endpoint,
      # Start a worker by calling: HT.Worker.start_link(arg)
      # {HT.Worker, arg}
      {HT.Repo, "database/"},
      {HT.Spacy, {"python3", "priv/python"}},
      {HT.ImageNet, {"python3", "priv/python"}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HT.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HTWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
