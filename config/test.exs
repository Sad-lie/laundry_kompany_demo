import Config

config :logger, level: :warning


# Configure your database
config :laundry_kompany_demo, LaundryKompanyDemo.Repo,
  database: Path.expand("../laundry_kompany_demo_test.sqlite", Path.dirname(__ENV__.file)),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :laundry_kompany_demo, LaundryKompanyDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "aFHIYE2BV8OW3jSvJe2RkHaaLCzqJTse9DrshG6idnzTKnj5MdY00F/Ip0oYKOCv",
  server: false

# In test we don't send emails
config :laundry_kompany_demo, LaundryKompanyDemo.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
