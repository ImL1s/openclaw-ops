---
name: openclaw-ops
description: OpenClaw 運維全指南 — 安裝設定、模型管理、遷移、cron 任務、安全檢查、除錯。當需要管理、遷移、排錯 OpenClaw 時使用此 skill。觸發關鍵字："OpenClaw 設定", "OpenClaw 遷移", "Gateway 管理", "cron 任務", "模型設定", "Telegram bot", "OpenClaw 安全檢查"。
---

# OpenClaw 運維全指南

> 實戰驗證於 2026-03-08 | OpenClaw 2026.3.2 | macOS (Apple Silicon)

本 skill 涵蓋 OpenClaw 的完整運維知識。以下是各文件索引和使用場景。

## 文件索引

### 安裝與設定
| 文件 | 場景 |
|------|------|
| [setup/openai-oauth.md](setup/openai-oauth.md) | 設定 OpenAI Codex OAuth（GPT-5.4 訂閱） |
| [setup/model-config.md](setup/model-config.md) | 主力/備援模型、別名、hot-reload 規則 |
| [setup/gateway.md](setup/gateway.md) | Gateway 服務管理、LaunchAgent、日誌 |

### 遷移
| 文件 | 場景 |
|------|------|
| [migration/mac-to-mac.md](migration/mac-to-mac.md) | Mac-to-Mac 遷移實戰紀錄（含踩坑） |

> 完整遷移 SOP 另見對應的 AI agent migration skill（如有設定）。

### 日常運維
| 文件 | 場景 |
|------|------|
| [cron/jobs-inventory.md](cron/jobs-inventory.md) | 全部 cron 任務清單、排程、外部依賴 |

### 安全
| 文件 | 場景 |
|------|------|
| [security/audit-guide.md](security/audit-guide.md) | 安全檢查指南、清理 checklist、假陽性說明 |
| [scripts/security-audit.sh](scripts/security-audit.sh) | 一鍵安全掃描（密碼/token/key/IP 洩漏偵測） |

### 排錯
| 文件 | 場景 |
|------|------|
| [troubleshooting/common-issues.md](troubleshooting/common-issues.md) | 10 個常見問題排解（附真實錯誤訊息） |

---

## 快速參考

### 常用指令
```bash
openclaw --version                      # 版本
openclaw gateway health                 # Gateway + Telegram 健康檢查
openclaw models status                  # 模型 + auth 狀態
openclaw cron list --all                # 所有 cron jobs
openclaw agents list                    # 所有 agents
openclaw channels status --probe        # 通道即時測試
openclaw cron run <job-id>              # 手動觸發 cron job
```

### 重啟 Gateway
```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

### 安全掃描
```bash
bash scripts/security-audit.sh
# 帶密碼掃描
AUDIT_PASSWORDS="mypassword" bash scripts/security-audit.sh
```

---

## 環境快照範例

> 根據你的實際部署修改以下值。

```
Primary Model : <your-primary-model>
Fallbacks     : <fallback-1>, <fallback-2>
Auth Providers: <provider-1> (OAuth), <provider-2> (OAuth), ...
Gateway       : port 18789, LaunchAgent, Telegram @<your-bot>
Active Cron   : <N> jobs (heartbeat, patrol, etc.)
CLI Tools     : gcloud, gh (<your-gh-user>), python3, curl, git
```

## 相關 Skills

如果你有設定對應的 AI agent skills，可參照：
- 跨機器遷移 SOP（7 Phase）
- 日常管理操作
