#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# start.sh — Bring up the monitoring stack
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

COMPOSE_FILE="$(dirname "$0")/../docker-compose.yml"
ENV_FILE="$(dirname "$0")/../.env"

# Load .env if it exists
if [[ -f "$ENV_FILE" ]]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

echo "🚀 Starting Docker Monitoring Stack..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo ""
echo "✅ Stack is up! Access the services:"
echo "   📊 Grafana:      http://localhost:3000  (admin / ${GRAFANA_ADMIN_PASSWORD:-changeme})"
echo "   🔥 Prometheus:   http://localhost:9090"
echo "   🔔 Alertmanager: http://localhost:9093"
echo "   📦 cAdvisor:     http://localhost:8080"
echo "   🖥️  Node Exporter: http://localhost:9100/metrics"
