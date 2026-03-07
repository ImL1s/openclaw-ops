#!/bin/bash
# OpenClaw Migration Security Audit Script
# Usage: bash security-audit.sh [path-to-deliverables...]
# If no paths given, scans default locations.

set -uo pipefail

echo "╔══════════════════════════════════════╗"
echo "║  OpenClaw Security Audit             ║"
echo "╚══════════════════════════════════════╝"

PASS=0; FAIL=0; WARN=0
pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN+1)); }

# Scan targets
TARGETS=("$@")
if [ ${#TARGETS[@]} -eq 0 ]; then
  # Default to the parent directory of this script
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TARGETS=(
    "${SCRIPT_DIR}/.."
  )
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. SSH Passwords
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 1. SSH Password Patterns ━━━"
echo "   (Add known passwords to AUDIT_PASSWORDS env var, comma-separated)"
IFS=',' read -ra PASSWORDS <<< "${AUDIT_PASSWORDS:-}"
if [ ${#PASSWORDS[@]} -eq 0 ]; then
  echo "  ℹ️  No passwords to check (set AUDIT_PASSWORDS=pw1,pw2)"
else
  for t in "${TARGETS[@]}"; do
    for pw in "${PASSWORDS[@]}"; do
      FOUND=$(grep -rn "$pw" "$t" 2>/dev/null | wc -l | tr -d ' ')
      [ "$FOUND" -eq 0 ] && pass "$t: no password leak" || fail "$t: PASSWORD FOUND ($FOUND hits)"
    done
  done
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. GitHub Tokens (gho_, ghp_, ghs_)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 2. GitHub Tokens ━━━"
for t in "${TARGETS[@]}"; do
  # Exclude pattern-match lines like: == gho_* || == ghp_*
  FOUND=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' 'gho_[A-Za-z0-9]{30,}|ghp_[A-Za-z0-9]{30,}|ghs_[A-Za-z0-9]{30,}' "$t" 2>/dev/null | wc -l | tr -d ' ')
  [ "$FOUND" -eq 0 ] && pass "$t: no gh tokens" || fail "$t: GH TOKEN ($FOUND hits)"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. GCloud Access Tokens
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 3. GCloud Access Tokens ━━━"
for t in "${TARGETS[@]}"; do
  FOUND=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' 'ya29\.[A-Za-z0-9_-]{20,}' "$t" 2>/dev/null | wc -l | tr -d ' ')
  [ "$FOUND" -eq 0 ] && pass "$t: no gcloud tokens" || fail "$t: GCLOUD TOKEN ($FOUND hits)"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. API Keys (AIza, sk-, Bearer)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 4. API Keys ━━━"
for t in "${TARGETS[@]}"; do
  FOUND=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' 'AIza[A-Za-z0-9_-]{30,}|sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9_.=-]{20,}' "$t" 2>/dev/null | wc -l | tr -d ' ')
  [ "$FOUND" -eq 0 ] && pass "$t: no API keys" || fail "$t: API KEY ($FOUND hits)"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. Private Keys (BEGIN RSA/EC/OPENSSH)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 5. Private Keys ━━━"
for t in "${TARGETS[@]}"; do
  FOUND=$(grep -rn --exclude='security-audit.sh' --exclude='audit-guide.md' "BEGIN.*PRIVATE KEY" "$t" 2>/dev/null | wc -l | tr -d ' ')
  [ "$FOUND" -eq 0 ] && pass "$t: no private keys" || fail "$t: PRIVATE KEY ($FOUND hits)"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. Hardcoded IPs (192.168.x.x in skills)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 6. Hardcoded IPs ━━━"
for t in "${TARGETS[@]}"; do
  FOUND=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' '192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+' "$t" 2>/dev/null | wc -l | tr -d ' ')
  [ "$FOUND" -eq 0 ] && pass "$t: no hardcoded IPs" || warn "$t: $FOUND IPs found (review if placeholders)"
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. PII: Emails, bot handles, usernames, home paths
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 7. PII (Personally Identifiable Info) ━━━"
for t in "${TARGETS[@]}"; do
  # Real emails (not <placeholder>@)
  EMAILS=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' '[a-zA-Z0-9._%+-]+@gmail\.com|@iam\.gserviceaccount\.com' "$t" 2>/dev/null | grep -v '<.*@' | wc -l | tr -d ' ')
  [ "$EMAILS" -eq 0 ] && pass "$t: no real emails" || warn "$t: $EMAILS email(s) (anonymize with <placeholder>)"

  # Telegram bot handles (@xxxbot)
  BOTS=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' '@[a-zA-Z0-9_]+bot\b' "$t" 2>/dev/null | grep -v '<.*bot' | wc -l | tr -d ' ')
  [ "$BOTS" -eq 0 ] && pass "$t: no bot handles" || warn "$t: $BOTS Telegram bot handle(s)"

  # Real home paths (/Users/username, not /Users/<)
  HOMES=$(grep -rEn --exclude='security-audit.sh' --exclude='audit-guide.md' '/Users/[a-zA-Z][a-zA-Z0-9_-]+/' "$t" 2>/dev/null | grep -v '/Users/<' | wc -l | tr -d ' ')
  [ "$HOMES" -eq 0 ] && pass "$t: no real home paths" || warn "$t: $HOMES real home path(s)"
done
echo ""
echo "━━━ 8. Temp Files ━━━"
TEMPS=$(find /tmp -maxdepth 1 -name "*.exp" -o -name "migrate*" -o -name "fix_*.sh" -o -name "check_*.sh" 2>/dev/null | wc -l | tr -d ' ')
[ "$TEMPS" -eq 0 ] && pass "/tmp: no migration scripts" || warn "/tmp: $TEMPS leftover scripts (run: rm -f /tmp/*.exp /tmp/migrate* /tmp/fix_*.sh)"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. Desktop Leftover Files
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━ 9. Desktop Cleanup ━━━"
[ ! -f "$HOME/Desktop/openclaw_migration.tar.gz" ] && pass "Desktop: no tar" || fail "Desktop: tar still exists"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "╔══════════════════════════════════════╗"
printf "║  ✅ %d passed  ⚠️  %d warnings  ❌ %d failed ║\n" $PASS $WARN $FAIL
echo "╚══════════════════════════════════════╝"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "🚨 FAILED — Fix the issues above before sharing!"
  exit 1
elif [ $WARN -gt 0 ]; then
  echo ""
  echo "⚠️  WARNINGS — Review manually."
  exit 0
else
  echo ""
  echo "🎉 ALL CLEAR — No sensitive data detected."
  exit 0
fi
