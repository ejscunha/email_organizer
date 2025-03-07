import Config

config :email_organizer,
  pub_sub_project_id: "project",
  pub_sub_topic: "topic",
  pub_sub_subscription: "subscription"

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :email_organizer, EmailOrganizer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "email_organizer_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :email_organizer, EmailOrganizerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gHVHIYOiqMpQbHTPZiy8jk/ZmrO31K95OEXGPJuqCy23V9WOU3aeYwxTf4s/8nyC",
  server: false

# Print only warnings and errors during test
config :logger, level: :none

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
