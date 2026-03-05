# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :laundry_kompany_demo,
  ecto_repos: [LaundryKompanyDemo.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :laundry_kompany_demo, LaundryKompanyDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: LaundryKompanyDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LaundryKompanyDemo.PubSub,
  live_view: [signing_salt: "57V8Aa9y"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :laundry_kompany_demo, LaundryKompanyDemo.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

config :laundry_kompany_demo,
  port: String.to_integer(System.get_env("PORT") || "4000"),
  whatsapp_token: "EAAWpW9xoq7cBQZBVv4YrfxyAhvcCWxqDCtIDAZBMZBNqIzpij2SaZACGmmMV8IrkyZB7Um9XFzh3ZAaDjVbnWNZClQehxRFIH4hyk96JWqyHZA0AY34w3AKub5usKJ5JJSctziyTd4fCBlHB98h4dSMZAj8YVokz5fqcnW9ckXuV9TLEduZAgNbmd7BsjjO2ZAYWsUUIZBUIOVQpmcoTOSfg9Gtvre5OQZBQT7v6FAarL4nmioUwvd9JOKwfFDq48F64XTARxNXy7OY9rqhLcPvyjM9EQvQZDZD",
  verify_token: System.get_env("VERIFY_TOKEN") || "laundry_kompany_token",
  whatsapp_phone_number_id: System.get_env("WHATSAPP_PHONE_NUMBER_ID")

import_config "#{config_env()}.exs"
