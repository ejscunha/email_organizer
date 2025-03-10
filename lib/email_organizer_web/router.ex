defmodule EmailOrganizerWeb.Router do
  use EmailOrganizerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EmailOrganizerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug EmailOrganizerWeb.Plug.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EmailOrganizerWeb do
    pipe_through [:browser, :auth]

    live_session :default,
      on_mount: EmailOrganizerWeb.AuthMount,
      layout: {EmailOrganizerWeb.Layouts, :app} do
      live "/", IndexLive
      live "/categories/new", CategoryLive.New
      live "/categories/:id/edit", CategoryLive.Edit
      live "/categories/:id", CategoryLive.Show
      live "/emails/:id", EmailLive.Show
    end
  end

  scope "/auth", EmailOrganizerWeb do
    pipe_through :browser

    get "/google", AuthController, :request
    get "/google/callback", AuthController, :callback
    get "/logout", AuthController, :logout
    get "/failed", AuthController, :failed
  end

  # Other scopes may use custom stacks.
  # scope "/api", EmailOrganizerWeb do
  #   pipe_through :api
  # end
end
