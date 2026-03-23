defmodule LaundryKompanyDemo.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false
  alias LaundryKompanyDemo.Repo

  alias LaundryKompanyDemo.Orders.Order
  alias LaundryKompanyDemo.Orders.Session

  # ── Orders ──────────────────────────────────────────────────────────────────

  def list_orders do
    Repo.all(Order) |> Repo.preload([])
  end

  def list_orders_by_phone(phone) do
    from(o in Order, where: o.phone == ^phone, order_by: [desc: :inserted_at])
    |> Repo.all()
  end

  def get_order!(id), do: Repo.get!(Order, id)

  def get_order_by_order_id(order_id) do
    from(o in Order, where: o.id == ^order_id, limit: 1)
    |> Repo.one()
  end

  def create_order(attrs \\ %{}) do
    order_id = generate_order_id()

    %Order{id: order_id}
    |> Order.changeset(attrs)
    |> Repo.insert!()
  end

  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  def update_order_status(order_id, status) when is_binary(status) do
    order = get_order_by_order_id(order_id)

    if order do
      update_order(order, %{status: status})
    else
      {:error, :not_found}
    end
  end

  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  defp generate_order_id do
    max_id = from(o in Order, select: max(o.id)) |> Repo.one() || "LKD-0000"
    {num, _} = Integer.parse(String.replace(max_id, "LKD-", ""))
    "LKD-" <> String.pad_leading("#{num + 1}", 4, "0")
  end

  # ── Sessions ────────────────────────────────────────────────────────────────

  def get_session(phone) do
    case Repo.get(Session, phone) do
      nil -> %{state: :idle, data: %{}}
      session -> %{state: String.to_atom(session.state), data: session.data || %{}}
    end
  end

  def put_session(phone, %{state: state, data: data}) do
    attrs = %{phone: phone, state: Atom.to_string(state), data: data}

    case Repo.get(Session, phone) do
      nil ->
        %Session{phone: phone}
        |> Session.changeset(attrs)
        |> Repo.insert!()

      session ->
        session
        |> Session.changeset(attrs)
        |> Repo.update!()
    end

    :ok
  end
end
