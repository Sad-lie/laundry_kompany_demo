defmodule LaundryKompanyDemo.OrderStore do
  @moduledoc """
  Simple in-memory store for orders and customer sessions.
  Replace with Ecto + PostgreSQL in production.
  """
  use GenServer

  # ── Public API ───────────────────────────────────────────────────────────────

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Get or create a session for a WhatsApp number."
  def get_session(phone), do: GenServer.call(__MODULE__, {:get_session, phone})

  @doc "Update a customer's session state."
  def put_session(phone, session), do: GenServer.cast(__MODULE__, {:put_session, phone, session})

  @doc "Create a new order."
  def create_order(order), do: GenServer.call(__MODULE__, {:create_order, order})

  @doc "Get an order by ID."
  def get_order(order_id), do: GenServer.call(__MODULE__, {:get_order, order_id})

  @doc "List all orders for a phone number."
  def list_orders(phone), do: GenServer.call(__MODULE__, {:list_orders, phone})

  @doc "Update order status."
  def update_order_status(order_id, status),
    do: GenServer.cast(__MODULE__, {:update_order_status, order_id, status})

  # ── GenServer Callbacks ───────────────────────────────────────────────────────

  @impl true
  def init(_) do
    {:ok, %{sessions: %{}, orders: %{}, counter: 1}}
  end

  @impl true
  def handle_call({:get_session, phone}, _from, state) do
    session = Map.get(state.sessions, phone, %{state: :idle, data: %{}})
    {:reply, session, state}
  end

  @impl true
  def handle_call({:create_order, order}, _from, state) do
    order_id = "LKD-#{String.pad_leading("#{state.counter}", 4, "0")}"
    new_order = Map.merge(order, %{id: order_id, created_at: DateTime.utc_now()})
    new_state = %{
      state
      | orders: Map.put(state.orders, order_id, new_order),
        counter: state.counter + 1
    }
    {:reply, new_order, new_state}
  end

  @impl true
  def handle_call({:get_order, order_id}, _from, state) do
    {:reply, Map.get(state.orders, order_id), state}
  end

  @impl true
  def handle_call({:list_orders, phone}, _from, state) do
    orders =
      state.orders
      |> Map.values()
      |> Enum.filter(&(&1.phone == phone))
      |> Enum.sort_by(& &1.created_at, {:desc, DateTime})

    {:reply, orders, state}
  end

  @impl true
  def handle_cast({:put_session, phone, session}, state) do
    {:noreply, %{state | sessions: Map.put(state.sessions, phone, session)}}
  end

  @impl true
  def handle_cast({:update_order_status, order_id, status}, state) do
    new_orders =
      Map.update(state.orders, order_id, nil, fn order ->
        Map.put(order, :status, status)
      end)

    {:noreply, %{state | orders: new_orders}}
  end
end
