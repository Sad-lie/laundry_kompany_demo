defmodule LaundryKompanyDemo.WhatsApp.ConversationHandler do
  @moduledoc """
  Laundry Kompany Demo — WhatsApp conversation state machine.

  ┌─────────────────────────────────────────────────────────────┐
  │  Flow 1  First Contact   → main_menu                        │
  │  Flow 2  Book Pickup     → pickup_date → pickup_time →      │
  │                            pickup_address → pickup_service → │
  │                            pickup_confirm → done            │
  │  Flow 3  Price Inquiry   → price_menu → price_detail        │
  │  Flow 4  Order Tracking  → await_order_id                   │
  │  Flow 5  Human Support   → support_menu → report_issue      │
  └─────────────────────────────────────────────────────────────┘
  """

  alias LaundryKompanyDemo.OrderStore

  # ─────────────────────────────────────────────────────────────────────────────
  # Public entry point
  # ─────────────────────────────────────────────────────────────────────────────

  @doc "Process an incoming message and return a reply string."
  def handle(phone, raw_message) do
    session = OrderStore.get_session(phone)
    text = raw_message |> String.trim() |> String.downcase()

    cond do
      greeting?(text) ->
        show_main_menu(phone)

      text in ["menu", "main menu", "0"] ->
        show_main_menu(phone)

      true ->
        route(phone, session, text)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # State router
  # ─────────────────────────────────────────────────────────────────────────────

  defp route(phone, %{state: :idle}, _text), do: show_main_menu(phone)
  defp route(phone, %{state: :main_menu}, text), do: handle_main_menu_choice(phone, text)

  # Flow 2 — Booking
  defp route(phone, %{state: :pickup_date}, text), do: handle_pickup_date(phone, text)

  defp route(phone, %{state: :pickup_custom_date}, text),
    do: handle_pickup_custom_date(phone, text)

  defp route(phone, %{state: :pickup_time, data: d}, text), do: handle_pickup_time(phone, d, text)

  defp route(phone, %{state: :pickup_address, data: d}, text),
    do: handle_pickup_address(phone, d, text)

  defp route(phone, %{state: :pickup_service, data: d}, text),
    do: handle_pickup_service(phone, d, text)

  defp route(phone, %{state: :pickup_confirm, data: d}, text),
    do: handle_pickup_confirm(phone, d, text)

  # Flow 3 — Pricing
  defp route(phone, %{state: :price_menu}, text), do: handle_price_menu(phone, text)

  # Flow 4 — Tracking
  defp route(phone, %{state: :await_order_id}, text), do: handle_order_tracking(phone, text)

  # Flow 5 — Support
  defp route(phone, %{state: :support_menu}, text), do: handle_support_menu(phone, text)
  defp route(phone, %{state: :report_issue}, text), do: handle_report_issue(phone, text)

  defp route(phone, _session, _text), do: show_main_menu(phone)

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 1 — First Contact / Main Menu
  # ─────────────────────────────────────────────────────────────────────────────

  defp show_main_menu(phone) do
    set_session(phone, :main_menu)

    """
    Hey 👋 Welcome to *Laundry Kompany Demo*!

    How can I help you today?

    1️⃣  Book a laundry pickup
    2️⃣  Check price list
    3️⃣  Track my order

    Reply with a number to get started.
    _(Type *menu* anytime to return here)_
    """
  end

  defp handle_main_menu_choice(phone, text) do
    case normalize(text) do
      x when x in ["1", "book", "book pickup", "pickup"] ->
        start_booking(phone)

      x when x in ["2", "price", "price list", "prices", "pricing"] ->
        show_price_menu(phone)

      x when x in ["3", "track", "track order", "track my order", "order"] ->
        start_tracking(phone)

      x when x in ["help", "complaint", "support", "agent"] ->
        show_support_menu(phone)

      _ ->
        """
        Sorry, I didn't quite get that 🤔

        Please reply with:
        *1* — Book a laundry pickup
        *2* — Check price list
        *3* — Track my order
        """
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 2 — Book a Pickup
  # ─────────────────────────────────────────────────────────────────────────────

  defp start_booking(phone) do
    set_session(phone, :pickup_date)

    """
    Great! Let's schedule your laundry pickup 🧺

    When should we collect it?

    1️⃣  Today
    2️⃣  Tomorrow
    3️⃣  Choose another date
    """
  end

  defp handle_pickup_date(phone, text) do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)

    case normalize(text) do
      x when x in ["1", "today"] ->
        save_and_ask_time(phone, Date.to_string(today), "Today")

      x when x in ["2", "tomorrow"] ->
        save_and_ask_time(phone, Date.to_string(tomorrow), "Tomorrow")

      x when x in ["3", "another", "choose", "other", "choose another date"] ->
        set_session(phone, :pickup_custom_date)
        "📅 Please type your preferred date in *DD/MM/YYYY* format (e.g. 25/06/2025)"

      _ ->
        """
        Please choose an option:
        *1* — Today
        *2* — Tomorrow
        *3* — Choose another date
        """
    end
  end

  defp handle_pickup_custom_date(phone, text) do
    case parse_date(text) do
      {:ok, date_str, label} -> save_and_ask_time(phone, date_str, label)
      :error -> "⚠️ Couldn't read that date. Please use *DD/MM/YYYY* format — e.g. *25/06/2025*."
    end
  end

  defp save_and_ask_time(phone, date_str, label) do
    put_session(phone, :pickup_time, %{date: date_str, date_label: label})

    """
    📅 Got it — *#{label}*!

    What time works best for pickup?

    1️⃣  Morning   (8am – 12pm)
    2️⃣  Afternoon (12pm – 5pm)
    3️⃣  Evening   (5pm – 8pm)
    """
  end

  defp handle_pickup_time(phone, data, text) do
    slot =
      case normalize(text) do
        x when x in ["1", "morning"] -> "Morning (8am – 12pm)"
        x when x in ["2", "afternoon"] -> "Afternoon (12pm – 5pm)"
        x when x in ["3", "evening"] -> "Evening (5pm – 8pm)"
        _ -> nil
      end

    if slot do
      put_session(phone, :pickup_address, Map.put(data, :time_slot, slot))
      "📍 Perfect! What's your *pickup address*?\n_(e.g. 15 Bode Thomas, Surulere, Lagos)_"
    else
      """
      Please choose a time slot:
      *1* — Morning (8am – 12pm)
      *2* — Afternoon (12pm – 5pm)
      *3* — Evening (5pm – 8pm)
      """
    end
  end

  defp handle_pickup_address(phone, data, address) do
    if String.length(address) < 5 do
      "⚠️ That address seems too short. Please enter your full street address."
    else
      put_session(phone, :pickup_service, Map.put(data, :address, address))

      """
      Got your address 📍

      What service do you need?

      1️⃣  🧺 Wash & Fold
      2️⃣  👔 Dry Cleaning
      3️⃣  👕 Ironing Only
      4️⃣  ✨ Wash & Iron
      """
    end
  end

  defp handle_pickup_service(phone, data, text) do
    service =
      case normalize(text) do
        x when x in ["1", "wash", "wash & fold", "wash and fold"] -> "Wash & Fold"
        x when x in ["2", "dry", "dry cleaning"] -> "Dry Cleaning"
        x when x in ["3", "iron", "ironing", "ironing only"] -> "Ironing Only"
        x when x in ["4", "wash & iron", "wash and iron"] -> "Wash & Iron"
        _ -> nil
      end

    if service do
      put_session(phone, :pickup_confirm, Map.put(data, :service, service))

      """
      Almost there! Here's your booking summary:

      ─────────────────────────
      📋 *Pickup Summary*
      ─────────────────────────
      📅 Date    : #{data.date_label} (#{data.date})
      ⏰ Time    : #{data.time_slot}
      📍 Address : #{data.address}
      🧺 Service : #{service}
      ─────────────────────────

      Reply *YES* to confirm or *NO* to cancel.
      """
    else
      """
      Please choose a service:
      *1* — 🧺 Wash & Fold
      *2* — 👔 Dry Cleaning
      *3* — 👕 Ironing Only
      *4* — ✨ Wash & Iron
      """
    end
  end

  defp handle_pickup_confirm(phone, data, text) do
    case normalize(text) do
      x when x in ["yes", "confirm", "ok", "yep", "yeah"] ->
        order =
          OrderStore.create_order(%{
            phone: phone,
            service: data.service,
            date: data.date,
            time: data.time_slot,
            address: data.address,
            status: :pending,
            kg: 0,
            total: 0
          })

        set_session(phone, :idle)

        """
        🎉 *Booking Confirmed!*

        Your pickup is scheduled for:
        📅 *#{data.date_label}* | ⏰ *#{data.time_slot}*
        📍 #{data.address}

        Your Order ID: *#{order.id}*

        We'll send you updates here on WhatsApp at every step.

        ─────────────────────────
        Need anything else? Type *menu* to go back.
        ─────────────────────────
        """

      x when x in ["no", "cancel", "nope"] ->
        set_session(phone, :idle)
        "No worries! Your booking was cancelled. Type *menu* to start over. 👋"

      _ ->
        "Please reply *YES* to confirm your booking or *NO* to cancel."
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 3 — Price List
  # ─────────────────────────────────────────────────────────────────────────────

  defp show_price_menu(phone) do
    set_session(phone, :price_menu)

    """
    Here's a quick look at our services 💧

    1️⃣  Wash & Fold pricing
    2️⃣  Dry Cleaning pricing
    3️⃣  Bulk / Commercial laundry

    Reply with the number to see details.
    _(Type *menu* to go back)_
    """
  end

  defp handle_price_menu(phone, text) do
    case normalize(text) do
      x when x in ["1", "wash", "wash & fold"] ->
        set_session(phone, :main_menu)

        """
        🧺 *Wash & Fold Pricing*
        ─────────────────────────
        Up to 3 kg   — ₦1,500
        3 – 7 kg     — ₦2,800
        7 – 10 kg    — ₦4,000
        10 kg+       — ₦450 / kg
        ─────────────────────────
        ⏱ Turnaround: *24 – 48 hours*
        🚗 Free pickup & delivery on orders above ₦3,000

        Type *1* to book a pickup or *menu* to go back.
        """

      x when x in ["2", "dry", "dry cleaning"] ->
        set_session(phone, :main_menu)

        """
        👔 *Dry Cleaning Pricing*
        ─────────────────────────
        Shirt / Blouse   — ₦800
        Trousers         — ₦900
        Suit (2-piece)   — ₦3,500
        Gown / Dress     — ₦2,000
        Duvet (single)   — ₦4,500
        Duvet (double)   — ₦6,000
        ─────────────────────────
        ⏱ Turnaround: *48 – 72 hours*

        Type *1* to book a pickup or *menu* to go back.
        """

      x when x in ["3", "bulk", "commercial"] ->
        set_session(phone, :main_menu)

        """
        🏭 *Bulk / Commercial Laundry*
        ─────────────────────────────
        We serve hotels, hospitals, salons & businesses.

        📦 Minimum order : 20 kg
        💰 Rate          : ₦300 / kg (negotiable for large volumes)
        🚛 We handle all pickup & delivery logistics

        📞 Call for a custom quote:
        *+234 800 LAUNDRY*

        Type *menu* to go back.
        """

      _ ->
        """
        Please reply with:
        *1* — Wash & Fold pricing
        *2* — Dry Cleaning pricing
        *3* — Bulk / Commercial laundry
        """
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 4 — Order Tracking
  # ─────────────────────────────────────────────────────────────────────────────

  defp start_tracking(phone) do
    set_session(phone, :await_order_id)

    """
    Sure thing 🔍 Please send your *Order ID* so I can check the status for you.

    Example: `LKD-0001`

    _(Type *menu* to go back)_
    """
  end

  defp handle_order_tracking(phone, text) do
    order_id = text |> String.upcase() |> String.trim()

    case OrderStore.get_order(order_id) do
      nil ->
        """
        ⚠️ I couldn't find an order with ID *#{order_id}*.

        Please double-check and try again, or type *menu* to go back.
        """

      order ->
        set_session(phone, :idle)

        """
        🔍 *Order Status*
        ─────────────────────────
        Order ID : *#{order.id}*
        Service  : #{order.service}
        Date     : #{Map.get(order, :date, "—")}
        Address  : #{order.address}
        Status   : #{status_emoji(order.status)} *#{format_status(order.status)}*
        ─────────────────────────
        #{next_step_message(order.status)}

        Type *menu* to go back.
        """
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 5 — Human Support
  # ─────────────────────────────────────────────────────────────────────────────

  defp show_support_menu(phone) do
    set_session(phone, :support_menu)

    """
    No problem — I'll connect you with our support team 🙋

    1️⃣  Talk to customer support
    2️⃣  Report an issue with an order
    3️⃣  Go back to main menu
    """
  end

  defp handle_support_menu(phone, text) do
    case normalize(text) do
      x when x in ["1", "talk", "agent", "support", "customer support"] ->
        set_session(phone, :idle)

        """
        📞 *Customer Support*
        ─────────────────────────
        Our team is available:
        🕗 Mon – Sat : 7am – 9pm
        🕗 Sunday    : 9am – 6pm

        📱 WhatsApp / Call : *+234 800 FRESPIN*
        📧 Email           : support@laundrykompany.demo
        ─────────────────────────
        An agent will respond within *15 minutes* during business hours.

        Type *menu* to go back.
        """

      x when x in ["2", "report", "issue", "problem", "complaint"] ->
        put_session(phone, :report_issue, %{})
        "Please describe the issue with your order.\n_(Include your Order ID if you have it)_"

      x when x in ["3", "back", "menu", "main menu"] ->
        show_main_menu(phone)

      _ ->
        """
        Please choose an option:
        *1* — Talk to customer support
        *2* — Report an issue with an order
        *3* — Go back to main menu
        """
    end
  end

  defp handle_report_issue(phone, description) do
    # In production: persist to DB and alert support team
    set_session(phone, :idle)

    """
    ✅ *Issue Reported!*

    Thank you for letting us know. Here's what you shared:

    _"#{String.slice(description, 0, 200)}"_

    Our support team will review this and get back to you within *1 hour* during business hours.

    📱 For urgent issues: *+234 800 FRESPIN*

    Type *menu* to go back to the main menu.
    """
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  defp set_session(phone, state),
    do: OrderStore.put_session(phone, %{state: state, data: %{}})

  defp put_session(phone, state, data),
    do: OrderStore.put_session(phone, %{state: state, data: data})

  defp greeting?(text) do
    text in [
      "hi",
      "hello",
      "hey",
      "start",
      "hii",
      "helo",
      "sup",
      "yo",
      "good morning",
      "good afternoon",
      "good evening"
    ]
  end

  defp normalize(text), do: text |> String.downcase() |> String.trim()

  defp parse_date(text) do
    cleaned = String.replace(text, "-", "/")

    case String.split(cleaned, "/") do
      [d, m, y] ->
        with {day, ""} <- Integer.parse(String.trim(d)),
             {mon, ""} <- Integer.parse(String.trim(m)),
             {year, ""} <- Integer.parse(String.trim(y)),
             {:ok, date} <- Date.new(year, mon, day) do
          label = Calendar.strftime(date, "%A, %d %B %Y")
          {:ok, Date.to_string(date), label}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp format_status(:pending), do: "Pending Pickup"
  defp format_status(:picked_up), do: "Picked Up"
  defp format_status(:washing), do: "Being Washed"
  defp format_status(:ready), do: "Ready for Delivery"
  defp format_status(:delivered), do: "Delivered"
  defp format_status(other), do: other |> to_string() |> String.capitalize()

  defp status_emoji(:pending), do: "⏳"
  defp status_emoji(:picked_up), do: "🚗"
  defp status_emoji(:washing), do: "🫧"
  defp status_emoji(:ready), do: "✅"
  defp status_emoji(:delivered), do: "🎉"
  defp status_emoji(_), do: "📦"

  defp next_step_message(:pending), do: "⏳ We'll be in touch to confirm your pickup time."
  defp next_step_message(:picked_up), do: "🚗 Your laundry is on its way to our facility!"
  defp next_step_message(:washing), do: "🫧 Our team is working on your items right now."
  defp next_step_message(:ready), do: "✅ Your laundry is clean and ready — delivery incoming!"
  defp next_step_message(:delivered), do: "🎉 All done! Enjoy your fresh laundry."
  defp next_step_message(_), do: "We'll keep you updated here on WhatsApp."
end
