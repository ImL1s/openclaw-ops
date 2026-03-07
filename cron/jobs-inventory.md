# Cron 任務清單與依賴

> 快照日期：2026-03-08 | 來源：目標機 <target-ip>

## 活躍任務範例

> 以下為範例格式，實際 job ID 和任務名稱依你的部署而定。

| ID (前8碼) | 名稱 | 排程 | 模型 | 外部依賴 |
|-----------|------|------|------|---------|
| `<job-id>` | Main heartbeat | every 5m | - | 無 |
| `<job-id>` | GitHub patrol | every 2h | - | `gh` CLI |
| `<job-id>` | Service health | every 1h | - | 無 |
| `<job-id>` | Morning brief | 09:00 TPE | - | 無 |
| `<job-id>` | Revenue report | 11:00 TPE | glm-5 | `gcloud` (AdMob API) |
| `<job-id>` | App stability report | 11:30 TPE | glm-5 | `gcloud` (Crashlytics) |
| `<job-id>` | Cloud billing report | 12:00 TPE | glm-5 | `gcloud` (Billing API) |
| `<job-id>` | GA4 weekly report | Mon 10:00 TPE | - | `gcloud` (GA4 API) |
| `<job-id>` | Social auto-poster | (自訂) | glm-5 | `curl` (Platform API) |

## 停用任務範例

| ID (前8碼) | 名稱 | 排程 | Agent |
|-----------|------|------|-------|
| `<job-id>` | `<agent-name>`-heartbeat | every 30m | `<agent-name>` |

## 外部依賴總結

| 工具 | 需要的 cron jobs | 認證方式 |
|------|-----------------|---------|
| `gcloud` | AdMob, Crashlytics, Billing, GA4, App review | `~/.config/gcloud/credentials.db` (可複製) |
| `gh` | GitHub patrol | macOS Keychain (需 `gh auth login` 或提取 token) |
| `curl` | x-auto-poster | 無特殊認證 |
| `python3` | 各種 exec skill script | 系統自帶 |

## 管理指令

```bash
# 列出所有
openclaw cron list --all

# 手動觸發
openclaw cron run <job-id>

# 停用/啟用
openclaw cron disable <job-id>
openclaw cron enable <job-id>
```
