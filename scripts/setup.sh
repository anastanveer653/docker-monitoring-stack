#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# setup.sh — Create .env with a random Grafana admin password
# ─────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

if [[ -f "${ENV_FILE}" ]]; then
  ok ".env already exists — leaving it untouched"
  exit 0
fi

password="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 || true)"
[[ ${#password} -eq 24 ]] || die "could not generate a random password"

sed "s/^GRAFANA_ADMIN_PASSWORD=.*/GRAFANA_ADMIN_PASSWORD=${password}/" \
  "${ROOT_DIR}/.env.example" > "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

ok "Created .env with a random Grafana admin password"
echo "   Read it with: grep GRAFANA_ADMIN_PASSWORD .env"
