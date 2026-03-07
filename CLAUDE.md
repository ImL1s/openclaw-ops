# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`openclaw-ops` is an operational knowledge base for managing OpenClaw AI agent deployments on macOS. It contains runbooks, troubleshooting guides, migration procedures, and automation scripts — not application code. All content is Markdown; the only executable is `scripts/security-audit.sh`.

## Repository Structure

```
setup/           — Configuration guides (models, OAuth, gateway)
migration/       — Machine-to-machine migration records
cron/            — Cron job inventory with external dependency mapping
troubleshooting/ — Categorized issue resolution (real error messages + fixes)
security/        — Audit guide and sensitive data policies
scripts/         — Automation scripts (security-audit.sh)
SKILL.md         — Root index file (YAML frontmatter + markdown), links to all docs
```

`SKILL.md` is the entry point — it indexes all documents by scenario and includes a quick-reference command table and an environment snapshot (current models, auth providers, active cron count).

## Key Commands

```bash
# Run security audit (checks for leaked tokens, PII, hardcoded IPs)
bash scripts/security-audit.sh

# Run with password leak detection
AUDIT_PASSWORDS="password1,password2" bash scripts/security-audit.sh

# Scan specific paths instead of entire repo
bash scripts/security-audit.sh ~/path/to/check/ ~/another/path.md
```

## Architecture Context

Understanding the system this repo documents:

```
Telegram Poll <-> [Gateway :18789] <-> AI Model APIs
                        |
                  RelayClient <-> Cloud Relay (<your-region>)
                        |
                  Cron Scheduler (17 active jobs)
```

- Gateway runs as a macOS **LaunchAgent** (`~/Library/LaunchAgents/ai.openclaw.gateway.plist`)
- Config lives in `~/.openclaw/openclaw.json`; auth tokens in `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
- **One bot token = one Gateway** — running two Gateways with the same Telegram bot token causes 409 conflicts and double cron execution
- Model/fallback/alias changes are **hot-reload**; auth/gateway port/plugin/channel changes require **Gateway restart**

## Content Conventions

- **All PII must be anonymized** — use `<placeholder>` format:
  - Emails: `<your-google-account>@gmail.com`
  - IPs: `<source-ip>`, `<target-ip>`
  - Usernames: `<your-gh-user>`, `<username>`
  - Bot handles: `@<your-bot>`
  - Home paths: `/Users/<username>/`
- **Error messages should be exact copies** from real encounters (grep-friendly)
- **Solutions must be verified** — each document header includes verification date and OpenClaw version (e.g., `> 驗證日期：2026-03-07 | OpenClaw 2026.3.2`)
- `SKILL.md` follows the OpenClaw skill format (YAML frontmatter + markdown)

## Security

Run `bash scripts/security-audit.sh` before every commit. The script checks:
- Credentials (SSH passwords, GitHub/GCloud tokens, API keys, private keys)
- PII (real emails, bot handles, home paths)
- Infrastructure (hardcoded IPs, temp file leftovers)

The audit self-excludes `security-audit.sh` and `audit-guide.md` to avoid false positives on pattern examples. See `security/audit-guide.md` for the full false-positive list.

Pre-commit hook setup: `.git/hooks/pre-commit` → `bash scripts/security-audit.sh`

## Cross-References

This repo documents the system. If corresponding AI agent skills are configured, they cover:
- Daily management operations
- Cross-machine migration SOP (7 phases)
