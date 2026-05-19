#!/usr/bin/env bash
# install_setup.sh — One-shot setup for Adobe Photoshop MCP on macOS.
#
# What it does (no user interaction beyond password prompts and the
# Xcode CLT system dialog):
#   1. Preflight: macOS, disk space, internet
#   2. Xcode Command Line Tools (installs if missing, polls until ready)
#   3. Detects (warns only) Photoshop and Claude Desktop installs
#   4. Homebrew (installs if missing)
#   5. python@3.12, node, uv, jq via Homebrew
#   6. Clones adb-mcp to ~/tools/adb-mcp
#   7. Creates an isolated venv and installs Python deps via uv sync
#   8. npm install for the Node proxy
#   9. Writes/merges Claude Desktop config to use the venv python
#  10. Verifies everything imports / loads / parses
#  11. Prints the only manual step (UXP plugin load) with the exact path
#
# Safe to re-run. Each phase is idempotent.

set -uo pipefail

# ---------- Config (hardcoded — verified against the real repo layout) ----------
REPO_URL="https://github.com/mikechambers/adb-mcp.git"
TOOLS_DIR="${HOME}/tools"
REPO_DIR="${TOOLS_DIR}/adb-mcp"
MCP_DIR="${REPO_DIR}/mcp"
MCP_ENTRY="${MCP_DIR}/ps-mcp.py"
PROXY_DIR="${REPO_DIR}/adb-proxy-socket"
PROXY_ENTRY="${PROXY_DIR}/proxy.js"
UXP_MANIFEST="${REPO_DIR}/uxp/ps/manifest.json"
# uv sync manages the venv next to pyproject.toml — let it own that location.
VENV_DIR="${MCP_DIR}/.venv"
VENV_PY="${VENV_DIR}/bin/python"
VENV_MCP="${VENV_DIR}/bin/mcp"

CLAUDE_CONFIG_DIR="${HOME}/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="${CLAUDE_CONFIG_DIR}/claude_desktop_config.json"

MIN_MACOS_MAJOR=12          # Monterey
MIN_PS_VERSION_MAJOR=26     # Photoshop 2025
MIN_DISK_FREE_GB=5

TOTAL_PHASES=10

# ---------- Pretty printing ----------
c_reset=$'\033[0m'; c_bold=$'\033[1m'
c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_blue=$'\033[34m'; c_dim=$'\033[2m'

phase() { printf "\n${c_bold}${c_blue}[%d/%d]${c_reset} ${c_bold}%s${c_reset}\n" "$1" "${TOTAL_PHASES}" "$2"; }
ok()    { printf "  ${c_green}✓${c_reset} %s\n" "$*"; }
warn()  { printf "  ${c_yellow}⚠${c_reset} %s\n" "$*"; }
err()   { printf "  ${c_red}✗${c_reset} %s\n" "$*" >&2; }
note()  { printf "  ${c_dim}%s${c_reset}\n" "$*"; }

die() {
  err "$1"
  [[ $# -gt 1 ]] && note "$2"
  exit 1
}

# ---------- 0. Banner ----------
clear
printf "${c_bold}Adobe Photoshop MCP — One-shot installer${c_reset}\n"
printf "%s\n" "================================================"
printf "Target user: %s\n" "$(whoami)"
printf "Target repo: %s\n" "${REPO_DIR}"
printf "%s\n" "================================================"

# ---------- 1. Preflight ----------
phase 1 "Preflight checks"

# 1a. macOS
[[ "$(uname)" == "Darwin" ]] || die "This installer only runs on macOS."
MACOS_VER="$(sw_vers -productVersion)"
MACOS_MAJOR="${MACOS_VER%%.*}"
if [[ "${MACOS_MAJOR}" -lt ${MIN_MACOS_MAJOR} ]]; then
  die "macOS ${MACOS_VER} is too old (need ${MIN_MACOS_MAJOR}+ Monterey)."
fi
ok "macOS ${MACOS_VER}"

# 1b. Disk space
FREE_KB="$(df -k "${HOME}" | awk 'NR==2 {print $4}')"
FREE_GB=$(( FREE_KB / 1024 / 1024 ))
if [[ ${FREE_GB} -lt ${MIN_DISK_FREE_GB} ]]; then
  die "Only ${FREE_GB} GB free on ${HOME}; need ${MIN_DISK_FREE_GB} GB."
fi
ok "Disk space: ${FREE_GB} GB free (need ${MIN_DISK_FREE_GB} GB)"

# 1c. Internet
if ! curl -fsSL --max-time 8 -o /dev/null https://github.com; then
  die "Can't reach github.com. Check your internet connection."
fi
ok "Internet reachable"

# 1d. Architecture
ARCH="$(uname -m)"
ok "Architecture: ${ARCH} ($([[ "${ARCH}" == "arm64" ]] && echo "Apple Silicon" || echo "Intel"))"

# ---------- 2. Xcode Command Line Tools ----------
phase 2 "Xcode Command Line Tools (provides git, compilers)"

if xcode-select -p &>/dev/null && git --version &>/dev/null; then
  ok "Xcode CLT already installed ($(xcode-select -p))"
else
  warn "Xcode CLT not found. Triggering install dialog..."
  note "A system popup will appear. Click 'Install' (NOT 'Get Xcode')."
  note "Download is ~1.5 GB. Expect 10–25 minutes depending on your connection."
  note "This installer will WAIT here — that's normal, don't close this window."
  xcode-select --install 2>/dev/null || true

  # Poll until both xcode-select -p AND git work.
  spin='|/-\'
  i=0
  start=$(date +%s)
  while ! ( xcode-select -p &>/dev/null && git --version &>/dev/null ); do
    elapsed=$(( $(date +%s) - start ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))
    i=$(( (i+1) % 4 ))
    printf "\r  ${c_yellow}${spin:$i:1}${c_reset} Waiting for Xcode CLT install... %dm%02ds elapsed   " "${mins}" "${secs}"
    sleep 5
  done
  printf "\r  ${c_green}✓${c_reset} Xcode CLT installed.                              \n"
fi

# ---------- 3. App detection (informational) ----------
phase 3 "Detecting Photoshop and Claude Desktop"

# Photoshop — find the highest-versioned install under /Applications.
PS_FOUND=""
PS_VER=""
shopt -s nullglob
for app in /Applications/Adobe\ Photoshop\ */Adobe\ Photoshop\ *.app; do
  [[ -d "${app}" ]] || continue
  v="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${app}/Contents/Info.plist" 2>/dev/null || echo "")"
  if [[ -n "${v}" && ( -z "${PS_VER}" || "${v}" > "${PS_VER}" ) ]]; then
    PS_FOUND="${app}"
    PS_VER="${v}"
  fi
done
shopt -u nullglob

if [[ -z "${PS_FOUND}" ]]; then
  warn "Adobe Photoshop not detected. Install Photoshop 2025 (26.0+) before using."
else
  PS_MAJOR="${PS_VER%%.*}"
  if [[ "${PS_MAJOR}" =~ ^[0-9]+$ && ${PS_MAJOR} -ge ${MIN_PS_VERSION_MAJOR} ]]; then
    ok "Photoshop ${PS_VER} found"
  else
    warn "Photoshop ${PS_VER} is too old (need ${MIN_PS_VERSION_MAJOR}.0+). UXP plugin may not load."
  fi
fi

if [[ -d "/Applications/Claude.app" ]]; then
  ok "Claude Desktop found"
else
  warn "Claude Desktop not detected. Install from https://claude.ai/download (config will still be written)."
fi

# ---------- 4. Homebrew ----------
phase 4 "Homebrew"

if ! command -v brew >/dev/null 2>&1; then
  # Source brew if a prior session installed it in a non-PATH location.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found. Installing (you will be prompted for your Mac password)."
  note "Password prompt is sudo asking permission. Characters are invisible — that's normal."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew install failed. See error above."
  # Make brew callable in this script run.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
command -v brew >/dev/null || die "Homebrew not on PATH after install."
ok "Homebrew $(brew --version | head -n1 | awk '{print $2}')"

# ---------- 5. Brew packages ----------
phase 5 "Installing python@3.12, node, uv, jq via Homebrew"

ensure_brew_pkg() {
  local pkg="$1"
  if brew list --formula --versions "${pkg}" &>/dev/null; then
    ok "${pkg} already installed"
  else
    note "Installing ${pkg}..."
    brew install "${pkg}" || die "brew install ${pkg} failed"
    ok "${pkg} installed"
  fi
}

ensure_brew_pkg python@3.12
ensure_brew_pkg node
ensure_brew_pkg uv
ensure_brew_pkg jq

# Resolve the specific python from the formula so it's stable across PATH order.
PYTHON_BIN="$(brew --prefix python@3.12)/bin/python3.12"
if [[ ! -x "${PYTHON_BIN}" ]]; then
  PYTHON_BIN="$(command -v python3)"
fi
NODE_BIN="$(command -v node)"
UV_BIN="$(command -v uv)"

ok "python   → ${PYTHON_BIN} ($(${PYTHON_BIN} --version))"
ok "node     → ${NODE_BIN} ($(${NODE_BIN} --version))"
ok "uv       → ${UV_BIN} ($(${UV_BIN} --version))"
ok "jq       → $(command -v jq)"

# ---------- 6. Clone repo ----------
phase 6 "Cloning adb-mcp"

mkdir -p "${TOOLS_DIR}"
if [[ -d "${REPO_DIR}/.git" ]]; then
  note "Repo exists — pulling latest..."
  git -C "${REPO_DIR}" pull --ff-only || warn "git pull failed; continuing with existing checkout."
  ok "Repo updated"
else
  git clone "${REPO_URL}" "${REPO_DIR}" || die "git clone failed."
  ok "Cloned to ${REPO_DIR}"
fi

# Verify the expected files exist in the cloned repo. If the upstream layout
# ever changes, fail loudly here instead of silently doing the wrong thing.
[[ -f "${MCP_ENTRY}" ]]    || die "Missing ${MCP_ENTRY}" "Upstream repo layout changed?"
[[ -f "${PROXY_ENTRY}" ]]  || die "Missing ${PROXY_ENTRY}" "Upstream repo layout changed?"
[[ -f "${UXP_MANIFEST}" ]] || die "Missing ${UXP_MANIFEST}" "Upstream repo layout changed?"
[[ -f "${MCP_DIR}/pyproject.toml" ]] || die "Missing ${MCP_DIR}/pyproject.toml"
ok "MCP entry:    ${MCP_ENTRY}"
ok "Proxy entry:  ${PROXY_ENTRY}"
ok "UXP manifest: ${UXP_MANIFEST}"

# ---------- 7. Python venv + deps ----------
phase 7 "Installing Python deps (uv sync at ${VENV_DIR})"

# Clean up legacy venv location from previous installer versions.
if [[ -d "${REPO_DIR}/.venv" && "${REPO_DIR}/.venv" != "${VENV_DIR}" ]]; then
  note "Removing legacy venv at ${REPO_DIR}/.venv"
  rm -rf "${REPO_DIR}/.venv"
fi

# Run uv sync in a clean subshell — unset conda/venv vars that would otherwise
# confuse uv's project-env discovery. uv creates and manages mcp/.venv itself.
(
  cd "${MCP_DIR}"
  unset VIRTUAL_ENV CONDA_PREFIX CONDA_DEFAULT_ENV CONDA_SHLVL
  "${UV_BIN}" sync --python "${PYTHON_BIN}"
) || die "uv sync failed. See errors above."

[[ -x "${VENV_PY}" ]] || die "uv did not create the expected venv at ${VENV_DIR}."
[[ -x "${VENV_MCP}" ]] || die "mcp CLI missing at ${VENV_MCP}. pyproject's mcp[cli] extra may have failed."
ok "Python deps installed → ${VENV_DIR}"

# ---------- 8. Node deps ----------
phase 8 "Installing Node proxy deps"

if [[ ! -f "${PROXY_DIR}/package.json" ]]; then
  die "Missing ${PROXY_DIR}/package.json"
fi

( cd "${PROXY_DIR}" && npm install --silent ) || die "npm install failed."
ok "npm install complete"

# ---------- 9. Claude Desktop config ----------
phase 9 "Writing Claude Desktop config"

mkdir -p "${CLAUDE_CONFIG_DIR}"
TMP_CONFIG="$(mktemp)"

# ps-mcp.py is loaded by the `mcp run` CLI (FastMCP entry). Plain
# `python ps-mcp.py` does NOT start the stdio server — it just defines
# tools and exits, which makes Claude Desktop report "Server disconnected".
if [[ -f "${CLAUDE_CONFIG_FILE}" ]]; then
  BACKUP="${CLAUDE_CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  cp "${CLAUDE_CONFIG_FILE}" "${BACKUP}"
  note "Existing config backed up to: $(basename "${BACKUP}")"
  jq \
    --arg cmd "${VENV_MCP}" \
    --arg arg "${MCP_ENTRY}" \
    '.mcpServers = (.mcpServers // {}) | .mcpServers.photoshop = {command: $cmd, args: ["run", $arg]}' \
    "${CLAUDE_CONFIG_FILE}" > "${TMP_CONFIG}" \
    || die "jq merge failed. Existing config may be invalid JSON: ${CLAUDE_CONFIG_FILE}"
else
  jq -n \
    --arg cmd "${VENV_MCP}" \
    --arg arg "${MCP_ENTRY}" \
    '{mcpServers: {photoshop: {command: $cmd, args: ["run", $arg]}}}' \
    > "${TMP_CONFIG}"
fi

# Validate before swapping in.
jq empty "${TMP_CONFIG}" || die "Generated config is invalid JSON."
mv "${TMP_CONFIG}" "${CLAUDE_CONFIG_FILE}"
ok "Wrote ${CLAUDE_CONFIG_FILE}"

# ---------- 10. Verification ----------
phase 10 "Verifying install"

# 10a. Venv python can import every required module.
"${VENV_PY}" - <<'PY' || die "Python deps failed to import. Re-run installer."
import importlib.util, sys
mods = ["mcp", "socketio", "fontTools", "requests", "websocket", "numpy", "PIL"]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
if missing:
    print("MISSING:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
print("OK: all modules importable")
PY
ok "Python deps import cleanly"

# 10b. Node proxy can be parsed (don't actually start it).
node --check "${PROXY_ENTRY}" || die "Node proxy has a syntax error."
ok "Node proxy parses cleanly"

# 10c. MCP entrypoint is syntactically valid Python.
"${VENV_PY}" -c "import ast,sys; ast.parse(open('${MCP_ENTRY}').read())" \
  || die "MCP entrypoint has a syntax error."
ok "MCP entrypoint parses cleanly"

# 10d. Claude config valid + has photoshop entry pointing at venv mcp CLI.
CONFIG_CMD="$(jq -r '.mcpServers.photoshop.command // ""' "${CLAUDE_CONFIG_FILE}")"
CONFIG_ARG0="$(jq -r '.mcpServers.photoshop.args[0] // ""' "${CLAUDE_CONFIG_FILE}")"
CONFIG_ARG1="$(jq -r '.mcpServers.photoshop.args[1] // ""' "${CLAUDE_CONFIG_FILE}")"
[[ "${CONFIG_CMD}" == "${VENV_MCP}" ]]  || die "Claude config command mismatch: ${CONFIG_CMD}"
[[ "${CONFIG_ARG0}" == "run" ]]         || die "Claude config args[0] should be 'run': ${CONFIG_ARG0}"
[[ "${CONFIG_ARG1}" == "${MCP_ENTRY}" ]] || die "Claude config args[1] mismatch: ${CONFIG_ARG1}"
ok "Claude Desktop config invokes: mcp run ps-mcp.py"

# ---------- Summary ----------
cat <<EOF

${c_bold}${c_green}════════════════════════════════════════════════════════${c_reset}
${c_bold}${c_green}  ✅ Automated setup complete.${c_reset}
${c_bold}${c_green}════════════════════════════════════════════════════════${c_reset}

${c_bold}ONE MANUAL STEP REMAINS — load the UXP plugin in Photoshop.${c_reset}
(Adobe doesn't allow this to be scripted.)

  1. Install Adobe UXP Developer Tool (UDT) if you don't have it:
       https://developer.adobe.com/photoshop/uxp/2022/guides/devtool/

  2. Open Adobe Photoshop. Then open UXP Developer Tool.

  3. In UDT, click ${c_bold}"Add Plugin..."${c_reset} (top right) and select:
       ${c_bold}${UXP_MANIFEST}${c_reset}
     (Copy/paste this path into the file picker — Cmd+Shift+G in Finder dialogs.)

  4. In UDT's plugin row, click the ${c_bold}•••${c_reset} menu → ${c_bold}Load${c_reset}.
     A "Claude" panel appears inside Photoshop.

${c_bold}DAILY USE${c_reset}

  • Double-click ${c_bold}StartSession.command${c_reset} before each work session.
  • In Photoshop, click ${c_bold}Connect${c_reset} in the Claude panel.
  • Open Claude Desktop and start chatting.

${c_bold}PATHS${c_reset}

  Repo:           ${REPO_DIR}
  Venv:           ${VENV_DIR}
  mcp CLI:        ${VENV_MCP}
  Claude config:  ${CLAUDE_CONFIG_FILE}

You can re-run this installer any time — it's idempotent.
EOF
