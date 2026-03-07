defmodule LaundryKompanyDemo.WhatsApp.MessageSender do
  @moduledoc """
  Sends messages via the WhatsApp Cloud API.
  """
  require Logger

  @api_base "https://graph.facebook.com/v22.0"

  defp get_config do
    Application.get_env(:laundry_kompany_demo, :whatsapp, [])
  end

  defp phone_number_id, do: Keyword.get(get_config(), :phone_number_id)
  defp access_token, do: Keyword.get(get_config(), :access_token)

  @doc """
  Send a plain text message to a WhatsApp number.
  """
  def send_text(to, text) do
    token = access_token()

    if is_nil(token) do
      Logger.warning("⚠️  WhatsApp access_token not set — skipping send. Reply would be:\n#{text}")
      {:ok, :skipped}
    else
      p_id = phone_number_id()
      Logger.info("📤 Phone ID: #{inspect(p_id)}")
      url = "#{@api_base}/#{p_id}/messages"
      Logger.info("📤 WhatsApp API URL: #{url}")
      Logger.info("📤 Recipient: #{to}")

      payload =
        Jason.encode!(%{
          messaging_product: "whatsapp",
          recipient_type: "individual",
          to: to,
          type: "text",
          text: %{
            preview_url: false,
            body: text
          }
        })

      headers = [
        {"Authorization", "Bearer #{access_token()}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.post(url, payload, headers) do
        {:ok, %{status_code: 200, body: body}} ->
          Logger.info("✅ Message sent to #{to}")
          {:ok, Jason.decode!(body)}

        {:ok, %{status_code: code, body: body}} ->
          Logger.error("❌ WhatsApp API error #{code}: #{body}")
          {:error, body}

        {:error, reason} ->
          Logger.error("❌ HTTP error: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Send interactive buttons to a WhatsApp number.
  """
  def send_buttons(to, text, buttons) when is_list(buttons) do
    token = access_token()

    if is_nil(token) do
      Logger.warning(
        "⚠️  WhatsApp access_token not set — skipping buttons. Reply would be:\n#{text}"
      )

      {:ok, :skipped}
    else
      url = "#{@api_base}/#{phone_number_id()}/messages"

      payload =
        Jason.encode!(%{
          messaging_product: "whatsapp",
          recipient_type: "individual",
          to: to,
          type: "interactive",
          interactive: %{
            type: "button",
            body: %{
              text: text
            },
            action: %{
              buttons:
                Enum.map(buttons, fn %{id: id, title: title} ->
                  %{type: "reply", reply: %{id: id, title: title}}
                end)
            }
          }
        })

      headers = [
        {"Authorization", "Bearer #{access_token()}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.post(url, payload, headers) do
        {:ok, %{status_code: 200, body: body}} ->
          Logger.info("✅ Buttons sent to #{to}")
          {:ok, Jason.decode!(body)}

        {:ok, %{status_code: code, body: body}} ->
          Logger.error("❌ WhatsApp buttons error #{code}: #{body}")
          {:error, body}

        {:error, reason} ->
          Logger.error("❌ HTTP error: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Send a template message (e.g., for order status updates).
  """
  def send_template(to, template_name, language \\ "en_US", components \\ []) do
    token = access_token()

    if is_nil(token) do
      Logger.warning("⚠️  WhatsApp access_token not set — skipping template send.")
      {:ok, :skipped}
    else
      url = "#{@api_base}/#{phone_number_id()}/messages"

      payload =
        Jason.encode!(%{
          messaging_product: "whatsapp",
          to: to,
          type: "template",
          template: %{
            name: template_name,
            language: %{code: language},
            components: components
          }
        })

      headers = [
        {"Authorization", "Bearer #{access_token()}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.post(url, payload, headers) do
        {:ok, %{status_code: 200, body: body}} ->
          {:ok, Jason.decode!(body)}

        {:ok, %{status_code: code, body: body}} ->
          Logger.error("❌ WhatsApp template error #{code}: #{body}")
          {:error, body}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
