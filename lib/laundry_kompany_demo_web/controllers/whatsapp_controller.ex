defmodule LaundryKompanyDemo.Controllers.WhatsAppController do
  @moduledoc """
  Handles incoming WhatsApp Cloud API webhooks.

  Endpoints:
    GET  /webhook  — Verification challenge (Meta setup)
    POST /webhook  — Incoming messages
  """

  import Plug.Conn
  require Logger

  alias LaundryKompanyDemo.WhatsApp.ConversationHandler
  alias LaundryKompanyDemo.WhatsApp.MessageSender

  defp get_verify_token do
    Application.get_env(:laundry_kompany_demo, :whatsapp, [])
    |> Keyword.get(:verify_token, "laundry_kompany_demo_token")
  end

  # ── GET /webhook — Meta verification ─────────────────────────────────────────

  def verify(conn) do
    params = conn.query_params

    hub_mode = Map.get(params, "hub.mode")
    hub_challenge = Map.get(params, "hub.challenge")
    hub_token = Map.get(params, "hub.verify_token")

    if hub_mode == "subscribe" and hub_token == get_verify_token() do
      Logger.info("✅ WhatsApp webhook verified successfully")

      conn
      |> send_resp(200, hub_challenge)
    else
      Logger.warning("❌ Webhook verification failed. Token mismatch.")

      conn
      |> send_resp(403, "Forbidden")
    end
  end

  # ── POST /webhook — Incoming messages ────────────────────────────────────────

  def handle(conn) do
    payload = conn.body_params

    case process_payload(payload) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "ok"}))

      _ ->
        conn
        |> send_resp(400, "Bad Request")
    end
  end

  # ── Payload Processing ────────────────────────────────────────────────────────

  defp process_payload(%{"object" => "whatsapp_business_account", "entry" => entries}) do
    for entry <- entries,
        change <- Map.get(entry, "changes", []),
        message <- get_in(change, ["value", "messages"]) || [] do
      handle_message(message, change["value"])
    end

    :ok
  end

  defp process_payload(_), do: :error

  defp handle_message(%{"type" => "text", "from" => phone, "text" => %{"body" => body}}, _value) do
    Logger.info("📨 Message from #{phone}: #{body}")

    reply = ConversationHandler.handle(phone, body)
    MessageSender.send_text(phone, reply)
  end

  defp handle_message(%{"type" => type, "from" => phone}, _value) do
    Logger.info("📨 Unsupported message type '#{type}' from #{phone}")
  end
end
