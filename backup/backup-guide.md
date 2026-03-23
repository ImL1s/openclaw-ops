# OpenClaw 完整備份與還原指南

> 驗證日期：2026-03-23 | OpenClaw 2026.3.x | macOS (Apple Silicon)

## 為什麼標準備份不夠？

OpenClaw 的 skills 常常依賴外部專案（自訂程式碼、Python venv、npm 專案、config 檔案）。只備份 `~/.openclaw/` 會遺漏這些外部依賴，導致還原後 skill 無法執行。

## 備份範圍

### 第一層：OpenClaw 核心（必備）

| 路徑 | 內容 |
|------|------|
| `~/.openclaw/openclaw.json` | 主設定（agents、models、channels、skills env） |
| `~/.openclaw/cron/jobs.json` | 排程任務 |
| `~/.openclaw/workspace/skills/` | 自裝 skills（ClawHub + 自製） |
| `~/.openclaw/workspace/memory/` | Agent 記憶 |
| `~/.openclaw/agents/` | Agent 設定 + auth profiles |
| `~/.openclaw/workspace/HEARTBEAT.md` | Heartbeat 指令 |

### 第二層：Skill 外部依賴（常被遺漏）

Skills 可能依賴 `~/.openclaw/` 以外的檔案。例如：
- 自訂專案程式碼（補丁過的 fork）
- Python venv / node_modules
- 專案 config 檔（含 API key）
- 瀏覽器 profile（自動化用）

這些需要透過 **manifest 檔** 宣告。

### 第三層：系統依賴

- Homebrew 套件（ffmpeg、imagemagick 等）
- Node.js 版本（nvm）
- Python 版本

## Manifest 檔

在 `~/.openclaw/backup-manifest.json` 宣告需要額外備份的路徑：

```json
{
  "version": 1,
  "external_paths": [
    {
      "label": "My custom project",
      "path": "~/Documents/mine/my-project",
      "include": ["src/", "config.json", ".env"],
      "exclude": ["node_modules/", "venv/", ".git/", "out/", "storage/"]
    }
  ],
  "brewfile": true,
  "post_restore": [
    "cd ~/Documents/mine/my-project && npm install",
    "cd ~/Documents/mine/my-project && python3.11 -m venv venv && ./venv/bin/pip install -r requirements.txt"
  ],
  "manual_steps": [
    "Open Firefox and log into required services"
  ]
}
```

### Manifest 欄位

| 欄位 | 必填 | 說明 |
|------|------|------|
| `external_paths[].label` | ✅ | 顯示名稱 |
| `external_paths[].path` | ✅ | 絕對路徑或 `~/` 開頭 |
| `external_paths[].include` | ❌ | 只備份這些子路徑（空 = 全部） |
| `external_paths[].exclude` | ❌ | 排除的目錄/檔案 |
| `brewfile` | ❌ | 是否產生 Brewfile（預設 true） |
| `post_restore` | ❌ | 還原後自動執行的指令 |
| `manual_steps` | ❌ | 還原後需要人工操作的步驟 |

## 使用方式

### 備份

```bash
bash scripts/backup.sh
# → ~/openclaw-backup-20260323.tar.gz

# 自訂輸出路徑
bash scripts/backup.sh /Volumes/External/backups/
```

### 還原

```bash
bash scripts/restore.sh ~/openclaw-backup-20260323.tar.gz
```

### 驗證

```bash
bash scripts/verify-backup.sh ~/openclaw-backup-20260323.tar.gz
```

## 安全注意事項

- 備份檔**包含 API keys 和 auth tokens** — 視同密碼保護
- 不要把備份推到公開 git repo
- 建議對備份檔加密：`gpg -c openclaw-backup.tar.gz`
- Firefox profile cookie 不建議備份 — 在新機器重新登入更安全
- 用 `scripts/security-audit.sh` 掃描備份目錄確認無洩漏
