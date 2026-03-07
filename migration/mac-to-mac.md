# Mac-to-Mac 遷移實戰記錄

> 日期：2026-03-08
> 源機：MacBook Pro (<source-ip>)
> 目標機：MacBook M1 Pro (<target-ip>)
> 耗時：約 25 分鐘（含排錯）

## 遷移清單

- [x] 打包源機 `~/.openclaw/` → 25MB tar.gz
- [x] 掃描 LAN 找到目標機 SSH
- [x] SCP 傳輸 (11.8MB/s)
- [x] 安裝 nvm + Node v22.20.0（目標機原 v20）
- [x] 安裝 OpenClaw 2026.3.2
- [x] 修復 config（移除 claw-link dev plugin）
- [x] Gateway install + start
- [x] 同步 gcloud SDK (711MB) + credentials
- [x] 複製 gh binary + 提取 Keychain token 注入
- [x] 停掉源機 Gateway
- [x] 完整驗證 29/29 ✅

## 踩過的坑

1. **Node 版本** — 目標機有 v20，OpenClaw 要 v22.12+
2. **nvm 不存在** — 目標機用系統 Node，沒裝 nvm
3. **expect password 格式** — macOS SSH prompt 是 `(user@host) Password:` 不是 `password:`
4. **openclaw doctor 卡住** — 互動式，在 expect 中無法使用
5. **plugin path** — `claw-link` 開發目錄不存在於目標機
6. **rsync ~ 路徑失敗** — SSH non-login shell 展開問題，要用絕對路徑
7. **Telegram 409** — 兩台 Gateway 搶同一個 bot token
8. **gh rsync 覆蓋** — 把目標機原有的有效 gh config 覆蓋掉了
9. **gh Keychain** — `hosts.yml` 只有帳號名，token 在 Keychain

## 最終驗證結果

```
29 passed, 0 failed
```

Core (2/2) | Gateway (3/3) | Models (7/7) | Cron (7/7) | CLI (7/7) | Live Test (1/1)

詳見對應的 AI agent migration skill（如有設定）。
