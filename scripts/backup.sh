#!/bin/bash
# OpenClaw Full Backup Script
# Backs up OpenClaw core + external dependencies declared in manifest
#
# Usage:
#   bash backup.sh                    # Output to ~/
#   bash backup.sh /path/to/dest/     # Output to custom dir
#   bash backup.sh --dry-run          # Show what would be backed up

set -uo pipefail

DEST_DIR="${1:-$HOME}"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && DEST_DIR="$HOME"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="openclaw-backup-${TIMESTAMP}"
BACKUP_DIR="/tmp/${BACKUP_NAME}"
MANIFEST="$HOME/.openclaw/backup-manifest.json"

echo "╔══════════════════════════════════════╗"
echo "║  OpenClaw Full Backup                ║"
echo "╚══════════════════════════════════════╝"
echo ""

ITEMS=0; SKIPPED=0; ERRORS=0
log_ok()   { echo "  ✅ $1"; ITEMS=$((ITEMS+1)); }
log_skip() { echo "  ⏭️  $1"; SKIPPED=$((SKIPPED+1)); }
log_err()  { echo "  ❌ $1"; ERRORS=$((ERRORS+1)); }

if $DRY_RUN; then
  echo "🔍 DRY RUN — nothing will be written"
  echo ""
fi

# ━━━ Layer 1: OpenClaw Core ━━━
echo "━━━ Layer 1: OpenClaw Core ━━━"

CORE_PATHS=(
  "$HOME/.openclaw/openclaw.json"
  "$HOME/.openclaw/cron"
  "$HOME/.openclaw/workspace/skills"
  "$HOME/.openclaw/workspace/memory"
  "$HOME/.openclaw/workspace/HEARTBEAT.md"
  "$HOME/.openclaw/agents"
)

for p in "${CORE_PATHS[@]}"; do
  if [ -e "$p" ]; then
    if ! $DRY_RUN; then
      REL_PATH="${p#$HOME/}"
      mkdir -p "${BACKUP_DIR}/core/$(dirname "$REL_PATH")"
      cp -a "$p" "${BACKUP_DIR}/core/${REL_PATH}" 2>/dev/null
    fi
    log_ok "$p"
  else
    log_skip "$p (not found)"
  fi
done

# ━━━ Layer 2: External Dependencies (from manifest) ━━━
echo ""
echo "━━━ Layer 2: External Dependencies ━━━"

if [ -f "$MANIFEST" ]; then
  log_ok "Manifest found: $MANIFEST"
  if ! $DRY_RUN; then
    cp "$MANIFEST" "${BACKUP_DIR}/backup-manifest.json"
  fi

  # Parse manifest with python3 (available on macOS)
  EXTERNAL_COUNT=$(python3 -c "
import json, sys
try:
    m = json.load(open('$MANIFEST'))
    paths = m.get('external_paths', [])
    print(len(paths))
except:
    print(0)
  ")

  if [ "$EXTERNAL_COUNT" -gt 0 ]; then
    python3 -c "
import json, os, subprocess, sys

manifest = json.load(open('$MANIFEST'))
backup_dir = '$BACKUP_DIR'
dry_run = $( $DRY_RUN && echo True || echo False )

for i, entry in enumerate(manifest.get('external_paths', [])):
    label = entry.get('label', f'path-{i}')
    src = os.path.expanduser(entry['path'])
    includes = entry.get('include', [])
    excludes = entry.get('exclude', ['node_modules/', 'venv/', '.git/', '__pycache__/'])

    if not os.path.exists(src):
        print(f'  ⏭️  {label}: {src} (not found)')
        continue

    if dry_run:
        print(f'  ✅ {label}: {src}')
        continue

    dest = os.path.join(backup_dir, 'external', label.replace(' ', '-').lower())
    os.makedirs(dest, exist_ok=True)

    rsync_cmd = ['rsync', '-a']
    for exc in excludes:
        rsync_cmd += ['--exclude', exc]

    if includes:
        for inc in includes:
            inc_src = os.path.join(src, inc)
            inc_dest = os.path.join(dest, inc)
            if os.path.isdir(inc_src):
                os.makedirs(inc_dest, exist_ok=True)
                subprocess.run(rsync_cmd + [inc_src + '/', inc_dest + '/'], capture_output=True)
            elif os.path.isfile(inc_src):
                os.makedirs(os.path.dirname(inc_dest), exist_ok=True)
                subprocess.run(['cp', inc_src, inc_dest], capture_output=True)
    else:
        subprocess.run(rsync_cmd + [src + '/', dest + '/'], capture_output=True)

    print(f'  ✅ {label}: {src}')
    "
  else
    log_skip "No external paths declared in manifest"
  fi

  # Post-restore commands (save for restore.sh)
  if ! $DRY_RUN; then
    python3 -c "
import json
m = json.load(open('$MANIFEST'))
cmds = m.get('post_restore', [])
steps = m.get('manual_steps', [])
with open('${BACKUP_DIR}/post-restore.sh', 'w') as f:
    f.write('#!/bin/bash\n')
    f.write('# Auto-generated post-restore commands\n\n')
    for cmd in cmds:
        f.write(f'{cmd}\n')
    if steps:
        f.write('\necho \"\"\n')
        f.write('echo \"⚠️  Manual steps required:\"\n')
        for s in steps:
            f.write(f'echo \"  - {s}\"\n')
" 2>/dev/null
  fi
else
  log_skip "No manifest found at $MANIFEST"
  echo "         Create one — see backup/backup-guide.md"
fi

# ━━━ Layer 3: System Dependencies ━━━
echo ""
echo "━━━ Layer 3: System Dependencies ━━━"

if ! $DRY_RUN; then
  mkdir -p "${BACKUP_DIR}/system"
fi

# Brewfile
if command -v brew &>/dev/null; then
  if ! $DRY_RUN; then
    brew bundle dump --file="${BACKUP_DIR}/system/Brewfile" --force 2>/dev/null
  fi
  log_ok "Brewfile generated"
else
  log_skip "Homebrew not found"
fi

# Node version
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  if ! $DRY_RUN; then
    echo "$NODE_VER" > "${BACKUP_DIR}/system/node-version.txt"
  fi
  log_ok "Node.js $NODE_VER"
else
  log_skip "Node.js not found"
fi

# Python version
if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version 2>&1)
  if ! $DRY_RUN; then
    echo "$PY_VER" > "${BACKUP_DIR}/system/python-version.txt"
  fi
  log_ok "$PY_VER"
else
  log_skip "Python3 not found"
fi

# OpenClaw version
if command -v openclaw &>/dev/null; then
  OC_VER=$(openclaw --version 2>/dev/null | head -1)
  if ! $DRY_RUN; then
    echo "$OC_VER" > "${BACKUP_DIR}/system/openclaw-version.txt"
  fi
  log_ok "OpenClaw $OC_VER"
else
  log_skip "OpenClaw not found"
fi

# ━━━ Create Archive ━━━
echo ""
if ! $DRY_RUN; then
  echo "━━━ Creating Archive ━━━"
  ARCHIVE="${DEST_DIR%/}/${BACKUP_NAME}.tar.gz"
  tar -czf "$ARCHIVE" -C /tmp "$BACKUP_NAME" 2>/dev/null
  rm -rf "$BACKUP_DIR"

  SIZE=$(du -h "$ARCHIVE" | cut -f1)
  echo "  📦 ${ARCHIVE} (${SIZE})"
fi

# ━━━ Summary ━━━
echo ""
echo "╔══════════════════════════════════════╗"
printf "║  ✅ %d items  ⏭️  %d skipped  ❌ %d errors  ║\n" $ITEMS $SKIPPED $ERRORS
echo "╚══════════════════════════════════════╝"

if ! $DRY_RUN; then
  echo ""
  echo "⚠️  Backup contains API keys/tokens — treat as sensitive!"
  echo "   Encrypt: gpg -c ${ARCHIVE}"
fi
