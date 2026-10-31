#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# smoke-test.sh — End-to-end checks against a running stack.
# Used by CI after `docker compose up --wait`; safe to run locally.
# Requires only curl.
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://localhost:9093}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
TIMEOUT="${SMOKE_TIMEOUT:-120}"

# shellcheck disable=SC1090
[[ -f "${ENV_FILE}" ]] && source "${ENV_FILE}"

# Evaluate a PromQL expression and print the first sample's value.
prom_value() {
  curl -fsS --get "${PROMETHEUS_URL}/api/v1/query" --data-urlencode "query=$1" \
    | sed -nE 's/.*"value":\[[^,]*,"([^"]*)"\].*/\1/p'
}

# Retry a check until it passes or TIMEOUT seconds elapse.
eventually() {
  local description="$1"; shift
  local deadline=$((SECONDS + TIMEOUT))
  until "$@"; do
    (( SECONDS < deadline )) || die "${description} (timed out after ${TIMEOUT}s)"
    sleep 5
  done
  ok "${description}"
}

all_targets_up()     { [[ "$(prom_value 'count(up == 0) or vector(0)')" == "0" ]]; }
host_metrics()       { [[ -n "$(prom_value 'node_memory_MemTotal_bytes')" ]]; }
container_metrics()  { [[ "$(prom_value 'count(container_last_seen{name="prometheus"})')" == "1" ]]; }
recording_rules()    { [[ -n "$(prom_value 'instance:node_cpu_utilisation:ratio')" ]]; }
rules_healthy()      { ! curl -fsS "${PROMETHEUS_URL}/api/v1/rules" | grep -q '"health":"err"'; }
watchdog_delivered() { curl -fsS "${ALERTMANAGER_URL}/api/v2/alerts?filter=alertname%3D%22Watchdog%22" | grep -q '"alertname":"Watchdog"'; }
grafana_dashboards() {
  local count
  count="$(curl -fsS -u "${GRAFANA_ADMIN_USER:-admin}:${GRAFANA_ADMIN_PASSWORD:?}" "${GRAFANA_URL}/api/search?type=dash-db" \
    | grep -o '"type":"dash-db"' | wc -l)"
  [[ "${count}" -eq "$(find "${ROOT_DIR}/grafana/dashboards" -name '*.json' | wc -l)" ]]
}
grafana_datasource() {
  curl -fsS -u "${GRAFANA_ADMIN_USER:-admin}:${GRAFANA_ADMIN_PASSWORD:?}" \
    "${GRAFANA_URL}/api/datasources/uid/prometheus/health" | grep -q '"status":"OK"'
}

info "Running smoke tests (timeout ${TIMEOUT}s per check)"
eventually "Every scrape target is up"                         all_targets_up
eventually "Node Exporter host metrics are ingested"           host_metrics
eventually "cAdvisor container metrics are ingested"           container_metrics
eventually "Recording rules produce data"                      recording_rules
eventually "All rule groups evaluate without errors"           rules_healthy
eventually "Watchdog alert reached Alertmanager"               watchdog_delivered
eventually "Grafana provisioned every dashboard"               grafana_dashboards
eventually "Grafana can query Prometheus"                      grafana_datasource

echo ""
ok "Smoke tests passed."
