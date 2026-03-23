#!/bin/bash
# OpenClaw Full Restore Script
# Restores from a backup created by backup.sh
#
# Usage:
#   bash restore.sh /path/to/openclaw-backup-20260323.tar.gz
#   bash restore.sh /path/to/backup.tar.gz --dry-run
#   bash restore.sh /path/to/backup.tar.gz --skip-deps

set -uo pipefail

ARCHIVE="${1:-}"
DRY_RUN=false
SKIP_DEPS=false

for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
  [[ "$arg" == "--skip-deps" ]] && SKIP_DEPS=true
done

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  echo "Usage: bash restore.sh <backup-archive.tar.gz> [--dry-run] [--skip-deps]"
  exit 1
fi

echo "╔══════════════════════════════════════╗"
echo "║  OpenClaw Full Restore               ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Archive: $ARCHIVE"
$DRY_RUN && echo "  Mode: DRY RUN"
echo ""

ITEMS=0; SKIPPED=0; ERRORS=0
log_ok()   { echo "  ✅ $1"; ITEMS=$((ITEMS+1)); }
log_skip() { echo "  ⏭️  $1"; SKIPPED=$((SKIPPED+1)); }
log_err()  { echo "  ❌ $1"; ERRORS=$((ERRORS+1)); }

# Extract to temp
RESTORE_DIR=$(mktemp -d)
tar -xzf "$ARCHIVE" -C "$RESTORE_DIR" 2>/dev/null
# Find the backup dir (first subdirectory)
BACKUP_DIR=$(find "$RESTORE_DIR" -maxdepth 1 -type d | tail -1)

if [ ! -d "${BACKUP_DIR}/core" ]; then
  echo "❌ Invalid backup archive — missing core/ directory"
  rm -rf "$RESTORE_DIR"
  exit 1
fi

# ━━━ Layer 1: OpenClaw Core ━━━
echo "━━━ Layer 1: Restoring OpenClaw Core ━━━"

if [ -f "${BACKUP_DIR}/core/.openclaw/openclaw.json" ]; then
  if ! $DRY_RUN; then
    # Backup existing config before overwriting
    if [ -f "$HOME/.openclaw/openclaw.json" ]; then
      cp "$HOME/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json.pre-restore"
      log_ok "Existing config backed up to openclaw.json.pre-restore"
    fi
    cp "${BACKUP_DIR}/core/.openclaw/openclaw.json" "$HOME/.openclaw/openclaw.json"
  fi
  log_ok "openclaw.json"
else
  log_skip "openclaw.json (not in backup)"
fi

# Cron
if [ -d "${BACKUP_DIR}/core/.openclaw/cron" ]; then
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.openclaw/cron"
    cp -a "${BACKUP_DIR}/core/.openclaw/cron/"* "$HOME/.openclaw/cron/" 2>/dev/null
  fi
  log_ok "cron/"
else
  log_skip "cron/ (not in backup)"
fi

# Skills
if [ -d "${BACKUP_DIR}/core/.openclaw/workspace/skills" ]; then
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.openclaw/workspace/skills"
    cp -a "${BACKUP_DIR}/core/.openclaw/workspace/skills/"* "$HOME/.openclaw/workspace/skills/" 2>/dev/null
  fi
  SKILL_COUNT=$(ls -1 "${BACKUP_DIR}/core/.openclaw/workspace/skills/" 2>/dev/null | wc -l | tr -d ' ')
  log_ok "workspace/skills/ (${SKILL_COUNT} skills)"
else
  log_skip "workspace/skills/ (not in backup)"
fi

# Memory
if [ -d "${BACKUP_DIR}/core/.openclaw/workspace/memory" ]; then
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.openclaw/workspace/memory"
    cp -a "${BACKUP_DIR}/core/.openclaw/workspace/memory/"* "$HOME/.openclaw/workspace/memory/" 2>/dev/null
  fi
  log_ok "workspace/memory/"
else
  log_skip "workspace/memory/"
fi

# Agents
if [ -d "${BACKUP_DIR}/core/.openclaw/agents" ]; then
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.openclaw/agents"
    cp -a "${BACKUP_DIR}/core/.openclaw/agents/"* "$HOME/.openclaw/agents/" 2>/dev/null
  fi
  log_ok "agents/"
else
  log_skip "agents/"
fi

# HEARTBEAT.md
if [ -f "${BACKUP_DIR}/core/.openclaw/workspace/HEARTBEAT.md" ]; then
  if ! $DRY_RUN; then
    cp "${BACKUP_DIR}/core/.openclaw/workspace/HEARTBEAT.md" "$HOME/.openclaw/workspace/HEARTBEAT.md"
  fi
  log_ok "HEARTBEAT.md"
else
  log_skip "HEARTBEAT.md"
fi

# ━━━ Layer 2: External Dependencies ━━━
echo ""
echo "━━━ Layer 2: Restoring External Dependencies ━━━"

if [ -d "${BACKUP_DIR}/external" ] && [ -f "${BACKUP_DIR}/backup-manifest.json" ]; then
  python3 -c "
import json, os, subprocess, sys

manifest = json.load(open('${BACKUP_DIR}/backup-manifest.json'))
backup_dir = '${BACKUP_DIR}'
dry_run = $( $DRY_RUN && echo True || echo False )

for entry in manifest.get('external_paths', []):
    label = entry.get('label', 'unknown')
    dest = os.path.expanduser(entry['path'])
    src = os.path.join(backup_dir, 'external', label.replace(' ', '-').lower())

    if not os.path.exists(src):
        print(f'  ⏭️  {label}: not in backup')
        continue

    if dry_run:
        print(f'  ✅ {label}: → {dest}')
        continue

    os.makedirs(dest, exist_ok=True)
    subprocess.run(['rsync', '-a', src + '/', dest + '/'], capture_output=True)
    print(f'  ✅ {label}: → {dest}')
  "
else
  log_skip "No external dependencies in backup"
fi

# ━━━ Layer 3: System Dependencies ━━━
echo ""
echo "━━━ Layer 3: System Dependencies ━━━"

if ! $SKIP_DEPS; then
  # Brewfile
  if [ -f "${BACKUP_DIR}/system/Brewfile" ]; then
    if ! $DRY_RUN; then
      echo "  📦 Installing brew packages..."
      brew bundle install --file="${BACKUP_DIR}/system/Brewfile" --no-lock 2>/dev/null
    fi
    log_ok "Brewfile restored"
  else
    log_skip "No Brewfile"
  fi

  # Node version
  if [ -f "${BACKUP_DIR}/system/node-version.txt" ]; then
    NEEDED=$(cat "${BACKUP_DIR}/system/node-version.txt")
    CURRENT=$(node --version 2>/dev/null || echo "none")
    if [ "$NEEDED" == "$CURRENT" ]; then
      log_ok "Node.js $CURRENT (match)"
    else
      log_err "Node.js mismatch: need $NEEDED, have $CURRENT"
      echo "         Fix: nvm install ${NEEDED#v}"
    fi
  fi
else
  log_skip "System deps skipped (--skip-deps)"
fi

# ━━━ Post-Restore Commands ━━━
echo ""
echo "━━━ Post-Restore ━━━"

if [ -f "${BACKUP_DIR}/post-restore.sh" ] && ! $DRY_RUN; then
  echo "  🔧 Running post-restore commands..."
  bash "${BACKUP_DIR}/post-restore.sh" 2>&1 | sed 's/^/    /'
  log_ok "Post-restore commands executed"
elif [ -f "${BACKUP_DIR}/post-restore.sh" ]; then
  echo "  📋 Post-restore commands (dry run):"
  cat "${BACKUP_DIR}/post-restore.sh" | grep -v '^#' | grep -v '^$' | sed 's/^/    /'
  log_ok "Post-restore commands listed"
else
  log_skip "No post-restore commands"
fi

# ━━━ Cleanup ━━━
rm -rf "$RESTORE_DIR"

# ━━━ Summary ━━━
echo ""
echo "╔══════════════════════════════════════╗"
printf "║  ✅ %d restored  ⏭️  %d skipped  ❌ %d errors ║\n" $ITEMS $SKIPPED $ERRORS
echo "╚══════════════════════════════════════╝"

if ! $DRY_RUN; then
  echo ""
  echo "📋 Next steps:"
  echo "  1. Restart gateway: openclaw gateway restart"
  echo "  2. Verify: openclaw gateway health"
  echo "  3. Check cron: openclaw cron list"
  echo "  4. Check skills: openclaw skills list"
  echo "  5. Re-authenticate if needed: openclaw configure --section model"
fi
