
# 🧺 Laundry Kompany Demo — WhatsApp API Backend

A fully working WhatsApp chatbot backend built in **Elixir** for a laundromat business. Uses the Meta/WhatsApp Cloud API.

---

## 🚀 Quick Start

### Prerequisites
- Elixir ~> 1.14
- Erlang/OTP 25+

### 1. Install dependencies
```bash
mix deps.get
```

### 2. Set environment variables
```bash
cp .env.example .env
# Edit .env with your Meta developer credentials
source .env
```

### 3. Run the server
```bash
mix run --no-halt
# Server starts on http://localhost:4000
```

---

## 🧪 Test the Bot Locally (No WhatsApp needed)

Use the `/simulate` endpoint to interact with the bot directly:

```bash
# Start a conversation
curl -X POST http://localhost:4000/simulate \
  -H "Content-Type: application/json" \
  -d '{"phone": "2348012345678", "message": "hi"}'

# Select a service
curl -X POST http://localhost:4000/simulate \
  -H "Content-Type: application/json" \
  -d '{"phone": "2348012345678", "message": "1"}'

# Enter weight
curl -X POST http://localhost:4000/simulate \
  -H "Content-Type: application/json" \
  -d '{"phone": "2348012345678", "message": "5"}'

# Enter address
curl -X POST http://localhost:4000/simulate \
  -H "Content-Type: application/json" \
  -d '{"phone": "2348012345678", "message": "15 Bode Thomas, Surulere, Lagos"}'

# Confirm order
curl -X POST http://localhost:4000/simulate \
  -H "Content-Type: application/json" \
  -d '{"phone": "2348012345678", "message": "YES"}'

# Check status
curl -X POST http://localhost:4000/simulate \
  -H "Content-Type: application/json" \
  -d '{"phone": "2348012345678", "message": "status"}'
```

---

## 💬 Conversation Flow

```
Customer sends "hi"
  └─> Bot shows service menu (Wash & Fold, Dry Cleaning, Ironing, Wash & Iron)
        └─> Customer picks 1–4
              └─> Bot asks for weight in kg
                    └─> Customer enters weight (e.g. "5")
                          └─> Bot asks for pickup address
                                └─> Customer enters address
                                      └─> Bot shows order summary, asks YES/NO
                                            └─> YES → Order confirmed with ID
                                            └─> NO  → Session reset
```

**Global keywords** (work from any state):
- `hi` / `hello` — restart conversation
- `status` — track orders
- `cancel` — reset session
- `help` — show menu

---

## 🔌 API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET`  | `/health` | Health check |
| `GET`  | `/webhook` | WhatsApp webhook verification |
| `POST` | `/webhook` | Receive WhatsApp messages |
| `POST` | `/simulate` | **Local testing** — send a message |
| `GET`  | `/api/orders?phone=...` | List customer orders |
| `GET`  | `/api/orders/:id` | Get a single order |
| `PATCH`| `/api/orders/:id/status` | Update order status |

### Admin: Update order status
```bash
curl -X PATCH http://localhost:4000/api/orders/LKD-0001/status \
  -H "Content-Type: application/json" \
  -d '{"status": "picked_up"}'
```

Valid statuses: `pending` → `picked_up` → `washing` → `ready` → `delivered`

When you update a status, the customer automatically gets a WhatsApp notification.

---

## 🏗 Project Structure

```
laundry_kompany_demo/
├── lib/laundry_kompany_demo/
│   ├── application.ex              # OTP supervisor
│   ├── router.ex                   # Plug HTTP router
│   ├── order_store.ex              # In-memory GenServer store
│   ├── controllers/
│   │   ├── whatsapp_controller.ex  # Webhook handler
│   │   └── admin_controller.ex     # Admin REST API
│   └── whatsapp/
│       ├── conversation_handler.ex # State machine / chat logic
│       └── message_sender.ex       # WhatsApp Cloud API client
├── config/
│   ├── config.exs
│   ├── dev.exs
│   └── prod.exs
├── test/
│   └── conversation_handler_test.exs
├── .env.example
└── mix.exs
```

---

## 📲 Connecting to Real WhatsApp (Meta Cloud API)

1. Go to [developers.facebook.com](https://developers.facebook.com)
2. Create a Meta App → Add "WhatsApp" product
3. Get your **Phone Number ID** and **Temporary Access Token**
4. Set your webhook URL to: `https://yourdomain.com/webhook`
5. Set your verify token to match `VERIFY_TOKEN` in your `.env`
6. Subscribe to the `messages` webhook field

---

## 🔄 Production Upgrades (TODO)

- [ ] Replace `OrderStore` GenServer with **Ecto + PostgreSQL**
- [ ] Add authentication middleware for admin endpoints
- [ ] Swap `HTTPoison` for `Req` (modern HTTP client)
- [ ] Add **Phoenix PubSub** for real-time order dashboard
- [ ] Deploy to **Fly.io** or **Render** with `mix release`

---

## 🧪 Run Tests

```bash
mix test
```

---

Made with ❤️ for Laundry Kompany.
