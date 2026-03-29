defmodule LaundryKompanyDemo.WhatsApp.ConversationHandler do
  @moduledoc """
  Laundry Kampany Demo — WhatsApp conversation state machine.

  Returns structured responses: {:text, body} or {:buttons, body, buttons}
  """

  alias LaundryKompanyDemo.OrderStore

  @doc "Process an incoming message and return a reply."
  def handle(phone, raw_message) do
    session = OrderStore.get_session(phone)
    text = raw_message |> String.trim() |> String.downcase()

    # Check if it's a button click (button ID)
    if button_click?(text, session) do
      route(phone, session, text)
    else
      cond do
        greeting?(text) ->
          show_main_menu(phone)

        text in ["menu", "main menu", "0"] ->
          show_main_menu(phone)

        # Handle direct navigation even from idle state
        text in ["1", "book", "pickup"] ->
          start_booking(phone)

        text in ["2", "price", "prices"] ->
          show_price_menu(phone)

        text in ["3", "track", "order"] ->
          start_tracking(phone)

        text in ["help", "support", "agent"] ->
          show_support_menu(phone)

        true ->
          route(phone, session, text)
      end
    end
  end

  # Check if the message is a button ID from previous interactive message
  defp button_click?(text, session) do
    case session do
      %{data: %{last_buttons: buttons}} when is_list(buttons) ->
        text in buttons

      _ ->
        false
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

    text = """
    Hey 👋 Welcome to *Laundry Kampany Demo*!

    How can I help you today?
    """

    buttons = [
      %{id: "main_book", title: "📦 Book Pickup"},
      %{id: "main_price", title: "💰 Price List"},
      %{id: "main_track", title: "🔍 Track Order"}
    ]

    # Store button IDs in session
    set_session_with_buttons(phone, :main_menu, buttons)
    {:buttons, text, buttons}
  end

  defp handle_main_menu_choice(phone, text) do
    choice = normalize(text)

    # Handle both text (1,2,3) and button clicks
    cond do
      choice in ["1", "book", "book pickup", "pickup", "main_book"] ->
        start_booking(phone)

      choice in ["2", "price", "price list", "prices", "pricing", "main_price"] ->
        show_price_menu(phone)

      choice in ["3", "track", "track order", "track my order", "order", "main_track"] ->
        start_tracking(phone)

      choice in ["help", "complaint", "support", "agent"] ->
        show_support_menu(phone)

      true ->
        show_main_menu(phone)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 2 — Book a Pickup
  # ─────────────────────────────────────────────────────────────────────────────

  defp start_booking(phone) do
    text = "Great! Let's schedule your laundry pickup 🧺\n\nWhen should we collect it?"

    buttons = [
      %{id: "date_today", title: "📅 Today"},
      %{id: "date_tomorrow", title: "📅 Tomorrow"},
      %{id: "date_other", title: "📅 Other Date"}
    ]

    set_session_with_buttons(phone, :pickup_date, buttons)
    {:buttons, text, buttons}
  end

  defp handle_pickup_date(phone, text) do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)
    choice = normalize(text)

    cond do
      choice in ["1", "today", "date_today"] ->
        save_and_ask_time(phone, Date.to_string(today), "Today")

      choice in ["2", "tomorrow", "date_tomorrow"] ->
        save_and_ask_time(phone, Date.to_string(tomorrow), "Tomorrow")

      choice in ["3", "another", "choose", "other", "choose another date", "date_other"] ->
        set_session(phone, :pickup_custom_date)
        {:text, "📅 Please type your preferred date in *DD/MM/YYYY* format (e.g. 25/06/2025)"}

      true ->
        start_booking(phone)
    end
  end

  defp handle_pickup_custom_date(phone, text) do
    case parse_date(text) do
      {:ok, date_str, label} -> save_and_ask_time(phone, date_str, label)
      :error -> "⚠️ Couldn't read that date. Please use *DD/MM/YYYY* format — e.g. *25/06/2025*."
    end
  end

  defp save_and_ask_time(phone, date_str, label) do
    buttons = [
      %{id: "time_morning", title: "🌅 Morning"},
      %{id: "time_afternoon", title: "☀️ Afternoon"},
      %{id: "time_evening", title: "🌆 Evening"}
    ]

    put_session(phone, :pickup_time, %{
      date: date_str,
      date_label: label,
      last_buttons: Enum.map(buttons, & &1.id)
    })

    text = "📅 Got it — *#{label}*!\n\nWhat time works best for pickup?"

    {:buttons, text, buttons}
  end

  defp handle_pickup_time(phone, data, text) do
    choice = normalize(text)

    time_slot =
      cond do
        choice in ["1", "morning", "time_morning"] -> "Morning (8am – 12pm)"
        choice in ["2", "afternoon", "time_afternoon"] -> "Afternoon (12pm – 5pm)"
        choice in ["3", "evening", "time_evening"] -> "Evening (5pm – 8pm)"
        true -> nil
      end

    if time_slot do
      data = Map.put(data, :time_slot, time_slot)
      ask_for_location(phone, data)
    else
      {:text,
       """
       Please choose a time slot:
       1️⃣ — Morning (8am – 12pm)
       2️⃣ — Afternoon (12pm – 5pm)
       3️⃣ — Evening (5pm – 8pm)
       """}
    end
  end

  defp handle_pickup_address(phone, data, address) do
    address = String.trim(address)

    cond do
      address == "skip_location" ->
        ask_for_manual_address(phone, data)

      String.length(address) < 5 ->
        ask_for_location(phone, data)

      true ->
        proceed_with_address(phone, data, address)
    end
  end

  defp ask_for_manual_address(phone, data) do
    text = "📝 Please type your full pickup address:\n_(e.g. 15 Bode Thomas, Surulere, Lagos)_"

    put_session(phone, :pickup_address, data)

    {:text, text}
  end

  defp ask_for_location(phone, data) do
    text =
      "📍 Please share your location for pickup:\n\nTap the 📎 attachment button → *Location* to share where we should pick up your laundry."

    buttons = [
      %{id: "skip_location", title: "📝 Type Address Instead"}
    ]

    new_data = Map.put(data, :last_buttons, ["skip_location"])
    put_session(phone, :pickup_address, new_data)

    {:buttons, text, buttons}
  end

  defp proceed_with_address(phone, data, address) do
    buttons = [
      %{id: "svc_washfold", title: "🧺 Wash & Fold"},
      %{id: "svc_dryclean", title: "👔 Dry Cleaning"},
      %{id: "svc_ironing", title: "👕 Ironing Only"}
    ]

    new_data = Map.put(data, :address, address)
    new_data = Map.put(new_data, :last_buttons, Enum.map(buttons, & &1.id))
    put_session(phone, :pickup_service, new_data)

    text = "Got your address 📍\n\nWhat service do you need?"

    {:buttons, text, buttons}
  end

  def handle_location(phone, latitude, longitude, address \\ nil) do
    session = OrderStore.get_session(phone)

    location_text = address || "#{latitude}, #{longitude}"

    proceed_with_address(phone, session.data, location_text)
  end

  defp handle_pickup_service(phone, data, text) do
    choice = normalize(text)

    service =
      cond do
        choice in ["1", "wash", "wash & fold", "wash and fold", "svc_washfold"] -> "Wash & Fold"
        choice in ["2", "dry", "dry cleaning", "svc_dryclean"] -> "Dry Cleaning"
        choice in ["3", "iron", "ironing", "ironing only", "svc_ironing"] -> "Ironing Only"
        choice in ["4", "wash & iron", "wash and iron"] -> "Wash & Iron"
        true -> nil
      end

    if service do
      buttons = [
        %{id: "confirm_yes", title: "✅ Confirm"},
        %{id: "confirm_no", title: "❌ Cancel"}
      ]

      new_data = Map.put(data, :service, service)
      new_data = Map.put(new_data, :last_buttons, Enum.map(buttons, & &1.id))
      put_session(phone, :pickup_confirm, new_data)

      date_label = Map.get(data, :date_label) || Map.get(data, "date_label") || "TBD"
      date = Map.get(data, :date) || Map.get(data, "date") || "TBD"
      time_slot = Map.get(data, :time_slot) || Map.get(data, "time_slot") || "TBD"
      address = Map.get(data, :address) || Map.get(data, "address") || "TBD"

      summary = """
      Almost there! Here's your booking summary:

      ─────────────────────────
      📋 *Pickup Summary*
      ─────────────────────────
      📅 Date    : #{date_label} (#{date})
      ⏰ Time    : #{time_slot}
      📍 Address : #{address}
      🧺 Service : #{service}
      ─────────────────────────
      """

      {:buttons, summary, buttons}
    else
      {:text,
       """
       Please choose a service:
       1️⃣ — 🧺 Wash & Fold
       2️⃣ — 👔 Dry Cleaning
       3️⃣ — 👕 Ironing Only
       4️⃣ — ✨ Wash & Iron
       """}
    end
  end

  defp handle_pickup_confirm(phone, data, text) do
    choice = normalize(text)

    service = Map.get(data, :service) || Map.get(data, "service")
    date = Map.get(data, :date) || Map.get(data, "date")
    time_slot = Map.get(data, :time_slot) || Map.get(data, "time_slot")
    address = Map.get(data, :address) || Map.get(data, "address")
    date_label = Map.get(data, :date_label) || Map.get(data, "date_label")

    cond do
      choice in ["yes", "confirm", "ok", "yep", "yeah", "confirm_yes"] ->
        order =
          OrderStore.create_order(%{
            phone: phone,
            service: service,
            date: date,
            time: time_slot,
            address: address,
            status: "pending",
            kg: 0,
            total: Decimal.new(0)
          })

        set_session(phone, :idle)

        {:text,
         """
         🎉 *Booking Confirmed!*

         Your pickup is scheduled for:
         📅 *#{date_label}* | ⏰ *#{time_slot}*
         📍 #{address}

         Your Order ID: *#{order.id}*

         We'll send you updates here on WhatsApp at every step.

         ─────────────────────────
         Need anything else? Type *menu* to go back.
         ─────────────────────────
         """}

      choice in ["no", "cancel", "nope", "confirm_no"] ->
        set_session(phone, :idle)
        {:text, "No worries! Your booking was cancelled. Type *menu* to start over. 👋"}

      true ->
        {:text, "Please confirm with *YES* or *NO*."}
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Flow 3 — Price List
  # ─────────────────────────────────────────────────────────────────────────────

  defp show_price_menu(phone) do
    text = "Here's a quick look at our services 💧"

    buttons = [
      %{id: "price_washfold", title: "🧺 Wash & Fold"},
      %{id: "price_dryclean", title: "👔 Dry Cleaning"},
      %{id: "price_bulk", title: "🏭 Bulk / Commercial"}
    ]

    set_session_with_buttons(phone, :price_menu, buttons)
    {:buttons, text, buttons}
  end

  defp handle_price_menu(phone, text) do
    choice = normalize(text)

    cond do
      choice in ["1", "wash", "wash & fold", "price_washfold"] ->
        set_session(phone, :main_menu)

        {:text,
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
         """}

      choice in ["2", "dry", "dry cleaning", "price_dryclean"] ->
        set_session(phone, :main_menu)

        {:text,
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
         """}

      choice in ["3", "bulk", "commercial", "price_bulk"] ->
        set_session(phone, :main_menu)

        {:text,
         """
         🏭 *Bulk / Commercial Laundry*
         ─────────────────────────────
         We serve hotels, hospitals, salons & businesses.

         📦 Minimum order : 20 kg
         💰 Rate          : ₦300 / kg (negotiable for large volumes)
         🚛 We handle all pickup & delivery logistics

         📞 Call for a custom quote:
         *+234 800 LAUNDRY*
         """}

      true ->
        {:text,
         """
         Please reply with:
         1️⃣ — Wash & Fold pricing
         2️⃣ — Dry Cleaning pricing
         3️⃣ — Bulk / Commercial laundry
         """}
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
        show_support_menu(phone)
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

  defp set_session_with_buttons(phone, state, buttons) do
    button_ids = Enum.map(buttons, & &1.id)
    OrderStore.put_session(phone, %{state: state, data: %{last_buttons: button_ids}})
  end

  defp greeting?(text) do
    text in [
      "hi",
      "hello",
      "hey",
      "hiya",
      "hii",
      "hiii",
      "helo",
      "hello!",
      "hi!",
      "hey!",
      "hy",
      "hya",
      "hola",
      "start",
      "sup",
      "yo",
      "good morning",
      "good afternoon",
      "good evening"
    ] or String.starts_with?(text, "hi") or String.starts_with?(text, "hey") or
      String.starts_with?(text, "hello")
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
