#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# stop.sh — Tear down the monitoring stack
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

COMPOSE_FILE="$(dirname "$0")/../docker-compose.yml"

echo "🛑 Stopping Docker Monitoring Stack..."
docker compose -f "$COMPOSE_FILE" down

echo "✅ Stack stopped. Data volumes are preserved."
echo "   To also remove volumes: docker compose down -v"
