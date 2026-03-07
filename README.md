# OpenClaw 運維知識庫 / OpenClaw Ops Knowledge Base

[中文](#中文) | [English](#english)

---

## 中文

本專案整理 OpenClaw AI agent 在 macOS 上的日常運維、設定、遷移、除錯實戰經驗。

### 作為 AI Agent Skill 使用

本 repo 包含 `SKILL.md`，可直接作為 AI coding agent 的 skill 使用。支援所有相容 [Agent Skills 開放標準](https://github.com/anthropics/skills) 的工具：

| 工具 | 安裝方式 |
|------|---------|
| **Claude Code** | `git clone` 到 `~/.claude/skills/openclaw-ops` |
| **Codex CLI** | `git clone` 到 `~/.codex/skills/openclaw-ops` |
| **Gemini CLI** | `git clone` 到 `~/.gemini/skills/openclaw-ops` |
| **Kiro / Antigravity** | `git clone` 到 `~/.agents/skills/openclaw-ops` |

```bash
# 範例：Claude Code
git clone https://github.com/ImL1s/openclaw-ops.git ~/.claude/skills/openclaw-ops

# 範例：Gemini CLI
git clone https://github.com/ImL1s/openclaw-ops.git ~/.gemini/skills/openclaw-ops
```

安裝後，AI agent 會在你詢問 OpenClaw 相關問題時自動載入此 skill。

### 目錄結構

```
setup/              設定指南（模型、OAuth、Gateway）
migration/          跨機器遷移實戰記錄
cron/               Cron 任務清單與外部依賴對照
troubleshooting/    常見問題排解（含真實錯誤訊息）
security/           安全檢查指南與敏感資料政策
scripts/            自動化腳本（安全掃描）
```

### 快速參考

| 命令 | 用途 |
|------|------|
| `openclaw --version` | 確認版本 |
| `openclaw gateway health` | 檢查 Gateway + Telegram |
| `openclaw models status` | 查看模型/認證狀態 |
| `openclaw cron list --all` | 列出所有 cron jobs |
| `openclaw agents list` | 列出所有 agents |
| `openclaw channels status --probe` | 測試通道連線 |

### 安全掃描

```bash
# 基本掃描（密鑰、PII、硬編碼 IP）
bash scripts/security-audit.sh

# 帶密碼洩漏偵測
AUDIT_PASSWORDS="password1,password2" bash scripts/security-audit.sh
```

每次 commit 前會自動執行（pre-commit hook）。

### 授權

[CC BY 4.0](LICENSE) — 自由使用，標註出處即可。

---

## English

Operational knowledge base for managing OpenClaw AI agent deployments on macOS. Covers setup, migration, cron jobs, troubleshooting, and security auditing — battle-tested with real error messages and verified solutions.

### Use as AI Agent Skill

This repo includes a `SKILL.md` and works as a skill for any AI coding agent that supports the [Agent Skills open standard](https://github.com/anthropics/skills):

| Tool | Install |
|------|---------|
| **Claude Code** | `git clone` to `~/.claude/skills/openclaw-ops` |
| **Codex CLI** | `git clone` to `~/.codex/skills/openclaw-ops` |
| **Gemini CLI** | `git clone` to `~/.gemini/skills/openclaw-ops` |
| **Kiro / Antigravity** | `git clone` to `~/.agents/skills/openclaw-ops` |

```bash
# Example: Claude Code
git clone https://github.com/ImL1s/openclaw-ops.git ~/.claude/skills/openclaw-ops

# Example: Gemini CLI
git clone https://github.com/ImL1s/openclaw-ops.git ~/.gemini/skills/openclaw-ops
```

Once installed, the AI agent automatically loads this skill when you ask about OpenClaw operations.

### Repository Structure

```
setup/              Configuration guides (models, OAuth, Gateway)
migration/          Machine-to-machine migration records
cron/               Cron job inventory with external dependency mapping
troubleshooting/    Categorized issue resolution (real error messages + fixes)
security/           Audit guide and sensitive data policies
scripts/            Automation scripts (security audit)
```

### Quick Reference

| Command | Purpose |
|---------|---------|
| `openclaw --version` | Check version |
| `openclaw gateway health` | Health check Gateway + Telegram |
| `openclaw models status` | View model/auth status |
| `openclaw cron list --all` | List all cron jobs |
| `openclaw agents list` | List all agents |
| `openclaw channels status --probe` | Test channel connectivity |

### Security Audit

```bash
# Basic scan (credentials, PII, hardcoded IPs)
bash scripts/security-audit.sh

# With password leak detection
AUDIT_PASSWORDS="password1,password2" bash scripts/security-audit.sh
```

Runs automatically on every commit via pre-commit hook.

### License

[CC BY 4.0](LICENSE) — Free to use with attribution.
