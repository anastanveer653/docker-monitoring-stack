#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# stop.sh — Tear down the monitoring stack (data volumes are kept)
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

require_docker
info "Stopping Docker Monitoring Stack..."
compose down

ok "Stack stopped. Data volumes are preserved."
echo "   To also delete all data: docker compose down -v"
