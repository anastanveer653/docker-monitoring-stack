#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# reload.sh — Validate, then hot-reload Prometheus and Alertmanager
#             configuration without restarting any container
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

require_docker

info "Validating Prometheus config and rules..."
# Runs inside the container, where the rule_files glob resolves; it also
# checks every rule file referenced by the config.
compose exec -T prometheus promtool check config /etc/prometheus/prometheus.yml

info "Validating Alertmanager config..."
compose exec -T alertmanager amtool check-config /etc/alertmanager/alertmanager.yml

info "Reloading Prometheus..."
compose exec -T prometheus wget -qO- --post-data='' http://localhost:9090/-/reload

info "Reloading Alertmanager..."
compose exec -T alertmanager wget -qO- --post-data='' http://localhost:9093/-/reload

ok "Configuration reloaded."
