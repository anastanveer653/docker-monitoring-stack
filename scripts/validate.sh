#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# validate.sh — Static checks for every config in the repo.
# Uses the exact image versions pinned in docker-compose.yml, so the
# only local requirement is Docker. Runs the same checks as CI.
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

require_docker

PROMETHEUS_IMAGE="$(image_of prom/prometheus)"
ALERTMANAGER_IMAGE="$(image_of prom/alertmanager)"

info "docker compose config"
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-validate}" compose config --quiet
ok "docker-compose.yml is valid"

info "promtool check config (${PROMETHEUS_IMAGE})"
docker run --rm --entrypoint promtool \
  -v "${MOUNT_DIR}/prometheus:/etc/prometheus:ro" \
  "${PROMETHEUS_IMAGE}" check config /etc/prometheus/prometheus.yml

info "promtool test rules"
docker run --rm --entrypoint promtool -w /work/prometheus \
  -v "${MOUNT_DIR}:/work:ro" \
  "${PROMETHEUS_IMAGE}" test rules tests/alerts_test.yml

info "amtool check-config (${ALERTMANAGER_IMAGE})"
docker run --rm --entrypoint amtool \
  -v "${MOUNT_DIR}/alertmanager:/etc/alertmanager:ro" \
  "${ALERTMANAGER_IMAGE}" check-config /etc/alertmanager/alertmanager.yml

info "Grafana dashboards"
cd "${ROOT_DIR}"   # relative paths work for both native and Windows tools
uids=()
for dashboard in grafana/dashboards/*.json; do
  if command -v jq >/dev/null 2>&1; then
    uid="$(jq -er 'select(.title and (.panels | length > 0)) | .uid' "${dashboard}")" \
      || die "${dashboard} is missing uid/title/panels"
  elif command -v node >/dev/null 2>&1; then
    uid="$(node -e 'const d=JSON.parse(require("fs").readFileSync(process.argv[1]));if(!d.uid||!d.title||!d.panels.length)process.exit(1);console.log(d.uid)' \
      "${dashboard}")" || die "${dashboard} is missing uid/title/panels"
  else
    warn "jq/node not found — skipping JSON validation"
    break
  fi
  [[ " ${uids[*]} " == *" ${uid} "* ]] && die "duplicate dashboard uid '${uid}' in ${dashboard}"
  uids+=("${uid}")
  ok "${dashboard} (uid: ${uid})"
done

echo ""
ok "All checks passed."
