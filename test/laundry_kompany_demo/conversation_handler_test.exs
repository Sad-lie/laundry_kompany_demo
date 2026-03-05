defmodule LaundryKompanyDemo.ConversationHandlerTest do
  use ExUnit.Case, async: false

  alias LaundryKompanyDemo.WhatsApp.ConversationHandler
  alias LaundryKompanyDemo.OrderStore

  setup do
    phone = "2348012345678"
    OrderStore.put_session(phone, %{state: :idle, data: %{}})
    {:ok, phone: phone}
  end

  test "greeting shows main menu", %{phone: phone} do
    reply = ConversationHandler.handle(phone, "hi")
    assert reply =~ "Laundry Kompany Demo"
    assert reply =~ "Book a laundry pickup"
  end

  test "menu returns to main menu", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    reply = ConversationHandler.handle(phone, "menu")
    assert reply =~ "Book a laundry pickup"
  end

  test "book pickup shows date options", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    reply = ConversationHandler.handle(phone, "1")
    assert reply =~ "schedule your laundry pickup"
    assert reply =~ "Today"
    assert reply =~ "Tomorrow"
  end

  test "select tomorrow shows time slots", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "1")
    reply = ConversationHandler.handle(phone, "2")
    assert reply =~ "What time works best"
  end

  test "select afternoon shows address input", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "1")
    ConversationHandler.handle(phone, "2")
    reply = ConversationHandler.handle(phone, "2")
    assert reply =~ "pickup address"
  end

  test "enter address shows service menu", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "1")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "2")
    reply = ConversationHandler.handle(phone, "123 Main St, Lagos")
    assert reply =~ "What service do you need"
    assert reply =~ "Wash & Fold"
  end

  test "select service shows confirmation", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "1")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "123 Main St, Lagos")
    reply = ConversationHandler.handle(phone, "1")
    assert reply =~ "Pickup Summary"
    assert reply =~ "YES"
  end

  test "confirm order creates order", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "1")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "123 Main St, Lagos")
    ConversationHandler.handle(phone, "1")
    reply = ConversationHandler.handle(phone, "yes")
    assert reply =~ "Booking Confirmed"
    assert reply =~ "LKD-"
  end

  test "cancel booking resets session", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "1")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "2")
    ConversationHandler.handle(phone, "123 Main St, Lagos")
    ConversationHandler.handle(phone, "1")
    reply = ConversationHandler.handle(phone, "no")
    assert reply =~ "cancelled"
  end

  test "price menu shows pricing options", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    reply = ConversationHandler.handle(phone, "2")
    assert reply =~ "Wash & Fold pricing"
  end

  test "track order asks for order id", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    reply = ConversationHandler.handle(phone, "3")
    assert reply =~ "Order ID"
  end

  test "tracking invalid order shows error", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    ConversationHandler.handle(phone, "3")
    reply = ConversationHandler.handle(phone, "LKD-9999")
    assert reply =~ "couldn't find"
  end

  test "support menu shows options", %{phone: phone} do
    ConversationHandler.handle(phone, "hi")
    reply = ConversationHandler.handle(phone, "help")
    assert reply =~ "support team"
  end
end
