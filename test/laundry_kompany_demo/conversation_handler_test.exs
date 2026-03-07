defmodule LaundryKompanyDemo.ConversationHandlerTest do
  use ExUnit.Case, async: true

  alias LaundryKompanyDemo.WhatsApp.ConversationHandler

  defp unique_phone, do: :erlang.unique_integer() |> to_string()

  test "greeting works" do
    reply = ConversationHandler.handle(unique_phone(), "hi")
    assert reply != nil
    # Returns either tuple or string
    text = if is_tuple(reply), do: elem(reply, 1), else: reply
    assert text =~ "Kampany"
  end

  test "price keyword works" do
    reply = ConversationHandler.handle(unique_phone(), "2")
    assert reply != nil
  end

  test "track keyword works" do
    reply = ConversationHandler.handle(unique_phone(), "3")
    assert reply != nil
  end

  test "help keyword works" do
    reply = ConversationHandler.handle(unique_phone(), "help")
    assert reply != nil
  end

  test "menu keyword works" do
    phone = unique_phone()
    ConversationHandler.handle(phone, "hi")
    reply = ConversationHandler.handle(phone, "menu")
    assert reply != nil
  end
end
