defmodule HTWeb.Router do
  use HTWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HTWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug BasicAuth, callback: &HTWeb.Auth.authorize_user/3
    plug HTWeb.SessionSetup
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HTWeb do
    pipe_through :browser

    live "/", ProjectLive.Index, :index
    live "/projects", ProjectLive.Index, :index
    live "/projects/new", ProjectLive.Index, :new
    live "/projects/:id/edit", ProjectLive.Index, :edit
    live "/projects/:id", ProjectLive.Show, :show
    live "/projects/:id/show/edit", ProjectLive.Show, :edit

    live "/examples", ExampleLive.Index, :index
    live "/examples/project/:project", ExampleLive.Index, :project
    live "/examples/label/:label", ExampleLive.Index, :label
    live "/examples/entity/:entity", ExampleLive.Index, :entity
    live "/examples/new", ExampleLive.Index, :new
    live "/examples/new/text/:text", ExampleLive.Index, :new_with_text
    live "/examples/:id/edit", ExampleLive.Index, :edit
    live "/examples/:id", ExampleLive.Show, :show
    live "/examples/:id/show/edit", ExampleLive.Show, :edit

    live "/predictions", PredictionLive, :index 
    live "/predictions/:sort", PredictionLive, :index 
    live "/test", TestLive, :index
    live "/train", TrainLive, :index
    live "/train/go", TrainLive, :go

  end

  scope "/api", HTWeb do
     pipe_through :api
     get "/predict", APIController, :predict
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HTWeb.Telemetry
    end
  end
end
