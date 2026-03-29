defmodule LaundryKompanyDemoWeb.Router do
  @moduledoc "Main HTTP router for Laundry Kompany Demo."

  use Plug.Router
  require Logger

  alias LaundryKompanyDemo.Controllers.{WhatsAppController, AdminController}

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason)
  plug(:dispatch)

  # ── Homepage ─────────────────────────────────────────────────────────────────

  get "/" do
    send_file(conn, 200, "priv/static/index.html")
  end

  # ── Health check ─────────────────────────────────────────────────────────────

  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "ok", service: "laundry_kompany_demo"}))
  end

  # ── WhatsApp Webhook ──────────────────────────────────────────────────────────

  get "/webhook" do
    WhatsAppController.verify(conn)
  end

  post "/webhook" do
    WhatsAppController.handle(conn)
  end

  # ── Simulation endpoint (for local testing without Meta) ──────────────────────

  post "/simulate" do
    params = conn.body_params

    with {:ok, phone} <- Map.fetch(params, "phone"),
         {:ok, message} <- Map.fetch(params, "message") do
      alias LaundryKompanyDemo.WhatsApp.ConversationHandler
      reply = ConversationHandler.handle(phone, message)

      # Handle both {:text, body} and {:buttons, body, buttons} formats
      response =
        case reply do
          {:text, text} -> %{type: "text", text: text}
          {:buttons, text, buttons} -> %{type: "buttons", text: text, buttons: buttons}
          text when is_binary(text) -> %{type: "text", text: text}
        end

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(response))
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{error: "Expected JSON body with 'phone' and 'message' fields"})
        )
    end
  end

  # ── Admin API ─────────────────────────────────────────────────────────────────

  get "/api/orders" do
    AdminController.list_orders(conn)
  end

  get "/api/orders/:id" do
    AdminController.get_order(conn, id)
  end

  patch "/api/orders/:id/status" do
    AdminController.update_status(conn, id)
  end

  # ── Admin Dashboard ──────────────────────────────────────────────────────────

  get "/admin" do
    send_file(conn, 200, "priv/static/admin/index.html")
  end

  # ── 404 Fallback ──────────────────────────────────────────────────────────────

  match _ do
    send_resp(conn, 404, Jason.encode!(%{error: "Not found"}))
  end
end
