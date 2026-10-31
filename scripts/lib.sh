#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# lib.sh — Shared helpers, sourced by the other scripts
# ─────────────────────────────────────────────────────────────────
# shellcheck disable=SC2034  # variables are used by the sourcing scripts

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/.env"
MOUNT_DIR="${ROOT_DIR}"

# Git Bash on Windows: docker.exe needs Windows paths, and MSYS must not
# rewrite container paths such as /etc/prometheus.
if command -v cygpath >/dev/null 2>&1; then
  MOUNT_DIR="$(cygpath -w "${ROOT_DIR}")"
  COMPOSE_FILE="$(cygpath -w "${COMPOSE_FILE}")"
  export MSYS_NO_PATHCONV=1
fi

if [[ -t 1 ]]; then
  BOLD=$'\e[1m'; GREEN=$'\e[32m'; RED=$'\e[31m'; YELLOW=$'\e[33m'; RESET=$'\e[0m'
else
  BOLD=""; GREEN=""; RED=""; YELLOW=""; RESET=""
fi

info()  { printf '%s==>%s %s\n' "${BOLD}" "${RESET}" "$*"; }
ok()    { printf '%s✔%s %s\n' "${GREEN}" "${RESET}" "$*"; }
warn()  { printf '%s!%s %s\n' "${YELLOW}" "${RESET}" "$*" >&2; }
die()   { printf '%s✖%s %s\n' "${RED}" "${RESET}" "$*" >&2; exit 1; }

compose() { docker compose -f "${COMPOSE_FILE}" "$@"; }

# Image tag pinned in docker-compose.yml, so validation uses the same versions.
image_of() {
  grep -E "^\s*image:\s*.*$1" "${COMPOSE_FILE}" | head -n1 | awk '{print $2}'
}

require_docker() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed"
  docker info >/dev/null 2>&1 || die "the Docker daemon is not running"
  docker compose version >/dev/null 2>&1 || die "the Docker Compose v2 plugin is required"
}
