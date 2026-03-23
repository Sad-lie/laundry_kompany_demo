defmodule LaundryKompanyDemo.OrderStore do
  @moduledoc """
  Order store backed by PostgreSQL database.
  Uses the Orders context for database operations.
  """
  use GenServer

  alias LaundryKompanyDemo.Orders

  # ── Public API ─────────────────────────────────────────────────────────────

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Get or create a session for a WhatsApp number."
  def get_session(phone), do: GenServer.call(__MODULE__, {:get_session, phone})

  @doc "Update a customer's session state."
  def put_session(phone, session), do: GenServer.cast(__MODULE__, {:put_session, phone, session})

  @doc "Create a new order."
  def create_order(attrs), do: GenServer.call(__MODULE__, {:create_order, attrs})

  @doc "Get an order by ID."
  def get_order(order_id), do: GenServer.call(__MODULE__, {:get_order, order_id})

  @doc "List all orders for a phone number."
  def list_orders(phone), do: GenServer.call(__MODULE__, {:list_orders, phone})

  @doc "List all orders."
  def list_all_orders, do: GenServer.call(__MODULE__, :list_all_orders)

  @doc "Update order status."
  def update_order_status(order_id, status),
    do: GenServer.cast(__MODULE__, {:update_order_status, order_id, status})

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get_session, phone}, _from, state) do
    session = Orders.get_session(phone)
    {:reply, session, state}
  end

  @impl true
  def handle_call({:create_order, attrs}, _from, state) do
    order = Orders.create_order(attrs)
    {:reply, order, state}
  end

  @impl true
  def handle_call({:get_order, order_id}, _from, state) do
    order = Orders.get_order_by_order_id(order_id)
    {:reply, order, state}
  end

  @impl true
  def handle_call({:list_orders, phone}, _from, state) do
    orders = Orders.list_orders_by_phone(phone)
    {:reply, orders, state}
  end

  @impl true
  def handle_call(:list_all_orders, _from, state) do
    orders = Orders.list_orders()
    {:reply, orders, state}
  end

  @impl true
  def handle_cast({:put_session, phone, session}, state) do
    Orders.put_session(phone, session)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_order_status, order_id, status}, state) do
    Orders.update_order_status(order_id, status)
    {:noreply, state}
  end
end
