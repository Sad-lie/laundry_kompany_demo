defmodule LaundryKompanyDemo.Controllers.AdminController do
  @moduledoc """
  Admin REST API for managing orders.
  """

  import Plug.Conn

  alias LaundryKompanyDemo.OrderStore
  alias LaundryKompanyDemo.WhatsApp.MessageSender

  @valid_statuses ~w(pending picked_up washing ready delivered)

  # ── GET /api/orders ──────────────────────────────────────────────────────────

  def list_orders(conn) do
    orders = OrderStore.list_all_orders()
    json_resp(conn, 200, %{orders: Enum.map(orders, &serialize_order/1)})
  end

  # ── GET /api/orders/:id ───────────────────────────────────────────────────────

  def get_order(conn, order_id) do
    case OrderStore.get_order(order_id) do
      nil -> json_resp(conn, 404, %{error: "Order not found"})
      order -> json_resp(conn, 200, %{order: serialize_order(order)})
    end
  end

  # ── PATCH /api/orders/:id/status ─────────────────────────────────────────────

  def update_status(conn, order_id) do
    params = conn.body_params

    with {:ok, status} <- Map.fetch(params, "status"),
         true <- status in @valid_statuses,
         order when not is_nil(order) <- OrderStore.get_order(order_id) do
      OrderStore.update_order_status(order_id, status)

      notify_customer(order, status)

      json_resp(conn, 200, %{message: "Status updated", order_id: order_id, status: status})
    else
      {:ok, _} ->
        json_resp(conn, 400, %{error: "Invalid or missing status"})

      false ->
        json_resp(conn, 400, %{
          error: "Status must be one of: #{Enum.join(@valid_statuses, ", ")}"
        })

      nil ->
        json_resp(conn, 404, %{error: "Order not found"})

      _ ->
        json_resp(conn, 400, %{error: "Bad request"})
    end
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp serialize_order(order) do
    %{
      id: order.id,
      phone: order.phone,
      service: order.service,
      date: Map.get(order, :date),
      time: Map.get(order, :time),
      address: order.address,
      status: order.status,
      inserted_at: order.inserted_at
    }
  end

  defp notify_customer(order, "picked_up") do
    msg =
      "🚗 *Order Update* — *#{order.id}*\n\nYour laundry has been picked up! We'll keep you posted. 🧺"

    MessageSender.send_text(order.phone, msg)
  end

  defp notify_customer(order, "washing") do
    msg = "🫧 *Order Update* — *#{order.id}*\n\nYour laundry is now being washed! ✨"
    MessageSender.send_text(order.phone, msg)
  end

  defp notify_customer(order, "ready") do
    msg =
      "✅ *Order Ready!* — *#{order.id}*\n\nYour laundry is clean and ready for delivery! We'll be with you shortly. 🎉"

    MessageSender.send_text(order.phone, msg)
  end

  defp notify_customer(order, "delivered") do
    msg =
      "🎉 *Order Delivered!* — *#{order.id}*\n\nYour laundry has been delivered. Enjoy your fresh clothes!\n\nThank you for choosing *Laundry Kampany*! 🧺"

    MessageSender.send_text(order.phone, msg)
  end

  defp notify_customer(_order, _status), do: :ok

  defp json_resp(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
