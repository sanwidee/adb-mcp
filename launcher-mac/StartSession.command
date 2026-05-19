#!/usr/bin/env bash
# StartSession.command — Daily launcher for Adobe Photoshop MCP.
# Double-click from Finder. Starts the Node proxy in the background and
# prints a friendly status. Press Ctrl+C or close this window to shut
# everything down cleanly.

set -uo pipefail

REPO_DIR="${HOME}/tools/adb-mcp"
PROXY_DIR="${REPO_DIR}/adb-proxy-socket"
PROXY_ENTRY="${PROXY_DIR}/proxy.js"
LOG_DIR="${REPO_DIR}/.logs"
PROXY_LOG="${LOG_DIR}/proxy.log"

c_reset=$'\033[0m'; c_bold=$'\033[1m'
c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_blue=$'\033[34m'

say()  { printf "${c_bold}${c_blue}▶${c_reset} %s\n" "$*"; }
ok()   { printf "${c_green}✓${c_reset} %s\n" "$*"; }
warn() { printf "${c_yellow}⚠${c_reset} %s\n" "$*"; }
err()  { printf "${c_red}✗${c_reset} %s\n" "$*" >&2; }

# Brew-installed node may not be on PATH for Finder-launched shells.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

pause_and_exit() {
  printf "\n"
  read -r -p "Press Return to close this window..." _
  exit "$1"
}

[[ -f "${PROXY_ENTRY}" ]] || { err "Proxy not found at ${PROXY_ENTRY}"; err "Run install_setup.sh first."; pause_and_exit 1; }
command -v node >/dev/null || { err "node not on PATH. Run install_setup.sh first."; pause_and_exit 1; }

mkdir -p "${LOG_DIR}"

clear
printf "${c_bold}Adobe Photoshop MCP — Session Launcher${c_reset}\n"
printf "%s\n" "----------------------------------------"

PROXY_PID=""
cleanup() {
  printf "\n"
  say "Shutting down..."
  if [[ -n "${PROXY_PID}" ]] && kill -0 "${PROXY_PID}" 2>/dev/null; then
    kill "${PROXY_PID}" 2>/dev/null || true
    sleep 0.5
    kill -9 "${PROXY_PID}" 2>/dev/null || true
  fi
  ok "Proxy stopped. Goodbye."
  sleep 1
}
trap cleanup EXIT INT TERM

say "Starting Node proxy: ${PROXY_ENTRY}"
( cd "${PROXY_DIR}" && node "${PROXY_ENTRY}" ) >"${PROXY_LOG}" 2>&1 &
PROXY_PID=$!

sleep 1
if ! kill -0 "${PROXY_PID}" 2>/dev/null; then
  err "Proxy failed to start. Last 20 lines of log:"
  tail -n 20 "${PROXY_LOG}" >&2 || true
  pause_and_exit 1
fi
ok "Proxy running (PID ${PROXY_PID}). Log: ${PROXY_LOG}"

printf "\n"
printf "${c_bold}${c_green}✅ Ready. Open Photoshop + Claude Desktop.${c_reset}\n\n"
printf "Next steps:\n"
printf "  1. Open Photoshop (if not already running).\n"
printf "  2. In the ${c_bold}Claude${c_reset} plugin panel inside Photoshop, click ${c_bold}Connect${c_reset}.\n"
printf "  3. Open Claude Desktop and start chatting.\n\n"
printf "${c_yellow}Keep this window open while you work.${c_reset}\n"
printf "Press ${c_bold}Ctrl+C${c_reset} (or close this window) to shut everything down.\n\n"

wait "${PROXY_PID}"
