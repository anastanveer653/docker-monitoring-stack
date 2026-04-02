#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# reload-prometheus.sh — Hot-reload Prometheus config without restart
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

echo "🔄 Reloading Prometheus configuration..."

# Validate config first
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
docker exec prometheus promtool check rules /etc/prometheus/rules/*.yml

# Trigger hot reload
curl -s -X POST http://localhost:9090/-/reload

echo "✅ Prometheus config reloaded successfully."
