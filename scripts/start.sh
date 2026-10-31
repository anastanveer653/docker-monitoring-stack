#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# start.sh — Bring up the monitoring stack and wait until it is healthy
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

require_docker
[[ -f "${ENV_FILE}" ]] || "${ROOT_DIR}/scripts/setup.sh"

info "Starting Docker Monitoring Stack..."
compose up -d --wait --wait-timeout 180

echo ""
ok "Stack is up and healthy:"
echo "   Grafana       http://localhost:3000   (user: admin, password in .env)"
echo "   Prometheus    http://localhost:9090"
echo "   Alertmanager  http://localhost:9093"
