# 常見問題排解

> 收集自 2026-03-07 ~ 2026-03-08 實際操作

## 1. `openclaw doctor` 卡住

**現象**: SSH 遠端執行 `openclaw doctor` 時無回應，一直掛著。

**原因**: `doctor` 是互動式指令，會等待 stdin 輸入。在 non-interactive SSH (如 expect script) 中會卡死。

**解法**: 跳過 `doctor`，直接跑：
```bash
openclaw gateway install
openclaw gateway start
```
Gateway 啟動時會自動修復大部分問題。

---

## 2. Config invalid: plugin path not found

**現象**:
```
plugins.load.paths: plugin: plugin path not found: /Users/.../plugins/claw-link
```

**原因**: 源機有開發用的本地 plugin 路徑，目標機沒有這個目錄。

**解法**: Python 修復腳本：
```python
import json, os
config_path = os.path.expanduser('~/.openclaw/openclaw.json')
with open(config_path) as f:
    c = json.load(f)
paths = c.get('plugins', {}).get('load', {}).get('paths', [])
valid = [p for p in paths if os.path.exists(p)]
if valid != paths:
    if valid:
        c['plugins']['load']['paths'] = valid
    else:
        del c['plugins']['load']['paths']
    with open(config_path, 'w') as f:
        json.dump(c, f, indent=2, ensure_ascii=False)
```

---

## 3. Node version too old

**現象**:
```
openclaw: Node.js v22.12+ is required (current: v20.19.0)
```

**解法**:
```bash
# 裝 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.zshrc
nvm install 22.20.0
nvm alias default 22.20.0
# 重裝 openclaw
npm install -g openclaw@2026.3.2
```

---

## 4. Telegram 409 衝突

**現象**:
```
[telegram] getUpdates conflict: terminated by other getUpdates request
```

**原因**: 兩台 Gateway 同時 polling 同一個 bot token。

**解法**: 停掉其中一台：
```bash
openclaw gateway stop
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
kill $(lsof -ti:18789) 2>/dev/null
```

---

## 5. RelayClient 不斷斷連重連

**現象**: gateway.log 中反覆出現：
```
[RelayClient] Disconnected from Relay Server.
[RelayClient] Connection lost. Attempting to reconnect in 1 second...
```

**原因**: 跟 Telegram 409 相同 — 兩台 Gateway 用同一個 relay token。

**解法**: 同上，停掉其中一台。

---

## 6. `gh auth` token 無法複製

**現象**: rsync `~/.config/gh/` 到新機器後，`gh auth status` 報 token invalid。

**原因**: `gh` 的 token 存在 macOS Keychain（透過 go-keyring），`hosts.yml` 只存帳號名。

**解法**: 從源機 Keychain 提取 token 注入：
```bash
# 源機：提取真實 token
RAW=$(gh auth token)
TOKEN=$(echo "${RAW#go-keyring-base64:}" | base64 -d)

# 注入目標機
ssh <target-user>@<target-ip> "echo '$TOKEN' | gh auth login --with-token"
```

> ⚠️ 注意：此操作會在 shell history 和 SSH 指令中短暫暴露 token。
> 建議操作完成後清理 `~/.zsh_history` 相關行。

---

## 7. `Unknown model` 錯誤

**現象**: `openclaw models status --probe` 顯示某模型為 "Unknown model"。

**原因**: OpenClaw 內建 catalog 不包含所有模型。模型實際可用，只是 catalog 沒列。

**解法**: 忽略此警告。透過 Telegram `/model` 選擇模型實測即可。

---

## 8. Gateway 啟動後 lsof 沒顯示 18789

**現象**: `openclaw gateway start` 成功但 `lsof -iTCP:18789` 空。

**原因**: Gateway 還在初始化（通常需要 5-10 秒）。

**解法**: 等 8-10 秒再查：
```bash
openclaw gateway start
sleep 10
lsof -iTCP:18789 -sTCP:LISTEN
```

---

## 9. rsync 到目標機失敗 (`No such file or directory`)

**現象**: `rsync ... user@target:~/.config/` 報 error。

**原因**: SSH non-login shell 的 `~` 展開不一致。

**解法**: 改用絕對路徑：
```bash
# ❌ 
rsync ... user@target:~/.config/gcloud/
# ✅ 
rsync ... user@target:/Users/<username>/.config/gcloud/
```

且先在目標機 `mkdir -p` 目標目錄。

---

## 10. SSH 登入時 `command not found: rbenv`

**現象**: 每次 SSH 登入目標機出現：
```
/Users/<username>/.zshenv:6: command not found: rbenv
```

**原因**: `.zshenv` 參照了 `rbenv`（Ruby 版本管理），但目標機沒裝。

**影響**: 純粹 cosmetic，不影響任何功能。

**解法**: 忽略，或在目標機 `.zshenv` 第 6 行加 `command -v rbenv &>/dev/null &&` 前綴。
