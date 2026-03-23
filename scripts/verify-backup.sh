#!/bin/bash
# OpenClaw Backup Verification Script
# Validates a backup archive without restoring it
#
# Usage: bash verify-backup.sh /path/to/backup.tar.gz

set -uo pipefail

ARCHIVE="${1:-}"

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  echo "Usage: bash verify-backup.sh <backup-archive.tar.gz>"
  exit 1
fi

echo "╔══════════════════════════════════════╗"
echo "║  OpenClaw Backup Verification        ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  Archive: $ARCHIVE"
SIZE=$(du -h "$ARCHIVE" | cut -f1)
echo "  Size: $SIZE"
echo ""

PASS=0; FAIL=0; WARN=0
pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN+1)); }

# Extract to temp for inspection
VERIFY_DIR=$(mktemp -d)
tar -xzf "$ARCHIVE" -C "$VERIFY_DIR" 2>/dev/null
BACKUP_DIR=$(find "$VERIFY_DIR" -maxdepth 1 -type d | tail -1)

echo "━━━ Structure ━━━"

# Core
[ -d "${BACKUP_DIR}/core" ] && pass "core/ directory exists" || fail "core/ missing"
[ -f "${BACKUP_DIR}/core/.openclaw/openclaw.json" ] && pass "openclaw.json" || fail "openclaw.json missing"
[ -d "${BACKUP_DIR}/core/.openclaw/cron" ] && pass "cron/" || warn "cron/ missing"
[ -d "${BACKUP_DIR}/core/.openclaw/workspace/skills" ] && pass "workspace/skills/" || warn "workspace/skills/ missing"
[ -d "${BACKUP_DIR}/core/.openclaw/agents" ] && pass "agents/" || warn "agents/ missing"

# System
echo ""
echo "━━━ System Info ━━━"
[ -d "${BACKUP_DIR}/system" ] && pass "system/ directory" || warn "system/ missing"
[ -f "${BACKUP_DIR}/system/Brewfile" ] && pass "Brewfile ($(wc -l < "${BACKUP_DIR}/system/Brewfile" | tr -d ' ') packages)" || warn "No Brewfile"
[ -f "${BACKUP_DIR}/system/node-version.txt" ] && pass "Node: $(cat "${BACKUP_DIR}/system/node-version.txt")" || warn "No node version"
[ -f "${BACKUP_DIR}/system/openclaw-version.txt" ] && pass "OpenClaw: $(cat "${BACKUP_DIR}/system/openclaw-version.txt")" || warn "No OpenClaw version"

# External
echo ""
echo "━━━ External Dependencies ━━━"
if [ -f "${BACKUP_DIR}/backup-manifest.json" ]; then
  pass "backup-manifest.json"
  EXTERNAL_COUNT=$(python3 -c "
import json, os
m = json.load(open('${BACKUP_DIR}/backup-manifest.json'))
paths = m.get('external_paths', [])
for p in paths:
    label = p.get('label', 'unknown')
    slug = label.replace(' ', '-').lower()
    ext_path = os.path.join('${BACKUP_DIR}', 'external', slug)
    if os.path.exists(ext_path):
        count = sum(len(files) for _, _, files in os.walk(ext_path))
        print(f'OK|{label} ({count} files)')
    else:
        print(f'MISS|{label}')
  " 2>/dev/null)

  while IFS= read -r line; do
    STATUS="${line%%|*}"
    DESC="${line#*|}"
    [ "$STATUS" == "OK" ] && pass "$DESC" || fail "$DESC — not found in archive"
  done <<< "$EXTERNAL_COUNT"
else
  warn "No manifest — external deps not tracked"
fi

# Post-restore
echo ""
echo "━━━ Restore Readiness ━━━"
[ -f "${BACKUP_DIR}/post-restore.sh" ] && pass "post-restore.sh present" || warn "No post-restore script"

# Security quick check
echo ""
echo "━━━ Security Quick Check ━━━"
API_KEYS=$(grep -rE 'AIza[A-Za-z0-9_-]{30,}|sk-[A-Za-z0-9]{20,}' "$BACKUP_DIR" 2>/dev/null | wc -l | tr -d ' ')
[ "$API_KEYS" -gt 0 ] && warn "Contains $API_KEYS API key reference(s) — encrypt before sharing" || pass "No exposed API keys in plaintext files"

# Cleanup
rm -rf "$VERIFY_DIR"

# Summary
echo ""
TOTAL=$((PASS + FAIL + WARN))
echo "╔══════════════════════════════════════╗"
printf "║  ✅ %d passed  ⚠️  %d warnings  ❌ %d failed  ║\n" $PASS $WARN $FAIL
echo "╚══════════════════════════════════════╝"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "🚨 Backup may be incomplete — review failed items"
  exit 1
elif [ $WARN -gt 0 ]; then
  echo ""
  echo "⚠️  Backup looks usable but has warnings"
  exit 0
else
  echo ""
  echo "🎉 Backup verified — ready for restore"
  exit 0
fi
