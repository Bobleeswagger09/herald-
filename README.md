# Herald

A real-time notification service built with **Elixir**, **Phoenix**, and **PostgreSQL**.
Handles concurrent user events and live WebSocket updates using OTP primitives.

## Architecture

PostgreSQL
└─ INSERT into notifications
└─ TRIGGER fires pg_notify('notifications_channel', payload)
└─ DBListener (Postgrex.Notifications GenServer)
└─ Phoenix.PubSub.broadcast("user:{id}", notification)
└─ UserSession GenServer (one per user)
└─ push to Phoenix Channel socket
└─ WebSocket client

## Tech Stack

- **Elixir 1.19 / OTP 27** — actor model, fault tolerance
- **Phoenix 1.7** — WebSocket channels, HTTP API
- **PostgreSQL 16** — persistence + LISTEN/NOTIFY for zero-poll real-time
- **Docker** — containerised deployment
- **GitHub Actions** — CI/CD pipeline

## Key Components

| Module                                   | Role                                            |
| ---------------------------------------- | ----------------------------------------------- |
| `Herald.Application`                     | OTP supervision tree                            |
| `Herald.DBListener`                      | PostgreSQL → PubSub bridge via LISTEN/NOTIFY    |
| `Herald.Workers.UserSession`             | Per-user GenServer, tracks delivery and retries |
| `HeraldWeb.Channels.NotificationChannel` | Phoenix Channel, WebSocket entry point          |
| `Herald.Notifications`                   | Ecto context, all DB access                     |

## Why This Design Scales

- Each connected user gets one lightweight BEAM process (~2KB heap).
  A single node handles 200,000+ concurrent connections.
- **DynamicSupervisor** starts and stops UserSession processes on demand.
  A crash in one session never affects others.
- **PostgreSQL LISTEN/NOTIFY** eliminates polling — the DB pushes changes instantly.
- **Phoenix.PubSub** fan-out works across a cluster of nodes with no extra infrastructure.

## Quick Start

### Prerequisites

- Elixir 1.16+
- PostgreSQL 16 (or Docker)
- Docker Desktop (optional)

### Run with Docker

```bash
docker compose up
```

### Run locally

```bash
# Start Postgres
docker run --name herald-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=herald_dev \
  -p 5432:5432 \
  -d postgres:16-alpine

# Install deps and set up DB
mix deps.get
mix ecto.setup

# Start server
mix phx.server
```

Server runs at `http://localhost:4000`
WebSocket at `ws://localhost:4000/socket`

## WebSocket Usage

```javascript
import { Socket } from "phoenix";

const socket = new Socket("/socket", { params: { token: userToken } });
socket.connect();

const channel = socket.channel(`notifications:${userId}`);

channel.on("new_notification", (notification) => {
  console.log("Received:", notification);
  channel.push("ack", { notification_id: notification.id });
});

channel.on("notification_list", ({ notifications }) => {
  console.log("Pending on connect:", notifications);
});

channel.join();
```

## REST API

```bash
# Create a notification
curl -X POST http://localhost:4000/api/notifications \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "message",
    "title": "Hello Herald",
    "body": "Your first notification"
  }'

# List notifications for a user
curl "http://localhost:4000/api/notifications?user_id=550e8400-e29b-41d4-a716-446655440000"

# Re-queue a failed notification
curl -X POST http://localhost:4000/api/notifications/{id}/requeue
```

## Running Tests

```bash
mix test
```

## Environment Variables (Production)

| Variable          | Description                          |
| ----------------- | ------------------------------------ |
| `DATABASE_URL`    | `ecto://user:pass@host/db`           |
| `SECRET_KEY_BASE` | Run `mix phx.gen.secret` to generate |
| `PHX_HOST`        | Your public hostname                 |
| `PORT`            | HTTP port (default 4000)             |
| `POOL_SIZE`       | DB connection pool size (default 10) |

## Project Structure

herald/
├── lib/
│ ├── herald/ # Business logic
│ │ ├── notifications/ # Ecto schema
│ │ ├── listeners/ # DB → PubSub bridge
│ │ └── workers/ # Per-user GenServers
│ └── herald_web/ # Web layer
│ ├── channels/ # WebSocket channels
│ └── controllers/ # REST API
├── priv/repo/migrations/ # DB migrations
├── config/ # Environment configs
├── Dockerfile
└── docker-compose.yml

## License

MIT
