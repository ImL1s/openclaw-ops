# Gateway 服務管理

> 驗證日期：2026-03-07 | OpenClaw 2026.3.2

## 架構

```
Telegram Poll ←→ [Gateway :18789] ←→ AI Model APIs
                      ↕
              RelayClient ←→ Cloud Relay (<your-region>)
                      ↕
              Cron Scheduler
```

## 服務管理

### 安裝為 LaunchAgent（開機自啟）
```bash
openclaw gateway install
# → ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

### 啟動/停止
```bash
# 推薦：用 launchctl
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist  # 啟動
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist   # 停止

# 或用 openclaw 指令
openclaw gateway start
openclaw gateway stop
```

### 健康檢查
```bash
openclaw gateway health
# → OK (1576ms)
# → Telegram: ok (@<your-bot>) (1576ms)
```

### 查看日誌
```bash
tail -f ~/.openclaw/logs/gateway.log      # 正常日誌
tail -f ~/.openclaw/logs/gateway.err.log  # 錯誤日誌
```

### 確認端口
```bash
lsof -iTCP:18789 -sTCP:LISTEN
```

## LaunchAgent Plist

位置：`~/Library/LaunchAgents/ai.openclaw.gateway.plist`

注意：
- 包含 Node.js 和 OpenClaw 的**絕對路徑**
- 換機器後需要 `openclaw gateway install` 重新生成
- `KeepAlive: true` — 進程掛掉會自動重啟

## Gateway Token

- 首次 `gateway install` 時自動生成
- 存在 `openclaw.json` 的 `gateway.token` 欄位
- 遷移時如果 config JSON 格式有問題，可能會報 `Warning: config file exists but is invalid; skipping token persistence`
- 跑 `openclaw doctor --fix` 可修復

## 重要限制

### Telegram Bot Token 衝突
一個 Bot Token 只能被**一個** Gateway polling。兩台同時跑 = 409 衝突：
```
[telegram] getUpdates conflict: terminated by other getUpdates request
```
解法：停掉其中一台。

### Cron Job 重複執行
兩台 Gateway 同時跑 = cron jobs 會**雙倍觸發**。確保只有一台在跑。
