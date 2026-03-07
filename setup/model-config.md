# 模型設定指南

> 驗證日期：2026-03-07 | OpenClaw 2026.3.2

## 當前設定

```
Primary:   zai/glm-5          ← 主力模型（GLM 5）
Fallback1: zai/glm-4.7        ← 備援 1
Fallback2: openai-codex/gpt-5.4 ← 備援 2（ChatGPT 訂閱）
```

## 別名（Aliases）

```
GLM Air     → zai/glm-4.5-air
GLM 5       → zai/glm-5
GLM 4.7     → zai/glm-4.7
Codex GPT-5.4 → openai-codex/gpt-5.4
```

Telegram `/model` 指令會顯示別名。

## 設定指令

```bash
# 設定主力模型
openclaw models set zai/glm-5

# 新增備援
openclaw models fallbacks add zai/glm-4.7
openclaw models fallbacks add openai-codex/gpt-5.4

# 新增別名
openclaw models aliases add "GLM 5" zai/glm-5

# 查看狀態
openclaw models status

# Probe 所有模型（測試連線）
openclaw models status --probe
```

## Hot Reload vs 重啟

| 設定項目 | Hot Reload | 需重啟 Gateway |
|---------|------------|---------------|
| model.primary | ✅ | |
| model.fallbacks | ✅ | |
| model.aliases | ✅ | |
| Auth profiles | | ✅ |
| Gateway port | | ✅ |
| Plugins | | ✅ |
| Channels | | ✅ |

## 重啟 Gateway

```bash
# 如果安裝為 LaunchAgent（推薦）
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# 或用 openclaw 指令
openclaw gateway stop && openclaw gateway start
```

## Auth Providers

已設定的 OAuth providers：
- **openai-codex** — GPT-5.4（ChatGPT 訂閱 OAuth）
- **anthropic** — Claude（claude-cli OAuth）
- **google-gemini-cli** — Gemini（Google OAuth, <your-google-account>@gmail.com）
- **qwen-portal** — Qwen（通義千問 OAuth）

驗證：
```bash
openclaw models status
# → Providers w/ OAuth/tokens (4): anthropic, google-gemini-cli, openai-codex, qwen-portal
```
