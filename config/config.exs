# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :email_organizer,
  ecto_repos: [EmailOrganizer.Repo],
  generators: [timestamp_type: :utc_datetime],
  pub_sub_project_id: {:system, "GOOGLE_CLOUD_PUBSUB_PROJECT_ID"},
  pub_sub_topic: {:system, "GOOGLE_CLOUD_PUBSUB_TOPIC"},
  pub_sub_subscription: {:system, "GOOGLE_CLOUD_PUBSUB_SUBSCRIPTION"}

# Configures the endpoint
config :email_organizer, EmailOrganizerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: EmailOrganizerWeb.ErrorHTML, json: EmailOrganizerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EmailOrganizer.PubSub,
  live_view: [signing_salt: "hWDGcfCx"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  email_organizer: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  email_organizer: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :reason]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Ueberauth
config :ueberauth, Ueberauth,
  providers: [
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "email profile",
         prompt: "select_account"
       ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: {System, :get_env, ["GOOGLE_CLIENT_ID"]},
  client_secret: {System, :get_env, ["GOOGLE_CLIENT_SECRET"]}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
