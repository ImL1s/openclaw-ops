# 安全檢查指南

> 每次遷移或涉及認證操作後必做

## 快速檢查

```bash
# 從 openclaw-ops 專案根目錄
bash scripts/security-audit.sh

# 指定掃描特定路徑
bash scripts/security-audit.sh ~/path/to/check/ ~/another/path.md

# 帶密碼模式（掃描特定密碼是否洩漏）
AUDIT_PASSWORDS="mypass1,mypass2" bash scripts/security-audit.sh
```

## 掃描項目

| 項目 | 檢測模式 | 風險等級 |
|------|---------|---------|
| SSH 密碼 | 使用者自定義 (`AUDIT_PASSWORDS`) | 🔴 Critical |
| GitHub tokens | `gho_`, `ghp_`, `ghs_` + 30+ chars | 🔴 Critical |
| GCloud tokens | `ya29.` + 20+ chars | 🔴 Critical |
| API keys | `AIza`, `sk-`, `Bearer` | 🔴 Critical |
| Private keys | `BEGIN.*PRIVATE KEY` | 🔴 Critical |
| 硬編碼 IP | `192.168.x.x`、`10.x.x.x` (所有檔案) | 🟡 Warning |
| PII: 真實 Email | `@gmail.com` (非 `<placeholder>@`) | 🟡 Warning |
| PII: Bot handles | `@xxxbot` (非 `<xxx>bot`) | 🟡 Warning |
| PII: Home paths | `/Users/<username>/` (非 `/Users/<>`) | 🟡 Warning |
| /tmp 殘留腳本 | `*.exp`, `migrate*`, `fix_*.sh` | 🟡 Warning |
| Desktop 遺留檔案 | `openclaw_migration.tar.gz` | 🟡 Warning |

## 遷移後安全清理 Checklist

- [ ] 跑 `bash scripts/security-audit.sh` 確認無洩漏
- [ ] 刪除 `/tmp/` 裡的 expect 腳本（含密碼）
- [ ] 刪除 Desktop 上的遷移包
- [ ] 清理目標機 `/tmp/` 裡的安裝腳本
- [ ] **考慮更換 SSH 密碼**（`passwd`）— 因為密碼在對話過程中被使用過
- [ ] 確認 `.zsh_history` 不含密碼（通常命令是從 agent 發的，不進 history）

## 假陽性說明

以下模式會被偵測到但實際上是安全的：

| 模式 | 出處 | 原因 |
|------|------|------|
| `gho_*` | bash 判斷式 | 模式匹配語法，非真 token |
| `go-keyring-base64:` | Troubleshooting 文件 | 格式名稱說明，非真 secret |

## 進階：git pre-commit hook

如果 `openclaw-ops` 加入 git，可設 pre-commit hook：
```bash
# .git/hooks/pre-commit
#!/bin/bash
bash scripts/security-audit.sh
```
這樣每次 commit 前自動掃描。
