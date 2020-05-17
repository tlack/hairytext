# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :hairytext,
  namespace: HT

# Configures the endpoint
config :hairytext, HTWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Y+TSJXMeIA6BwZ9NQ+ySxxbewW6D8xXRzJK/qV4sO3aP0tkeTIoQGjKD4n+sJini",
  render_errors: [view: HTWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HT.PubSub,
  live_view: [signing_salt: "k/H0AU5N"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :hairytext, HTWeb.Auth,
  users: %{ "admin" => "sohairy" }

config :hairytext, HT.ImageNet, 
  image_dir: "image_examples/"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
