# OpenAI Codex OAuth 設定指南

> 驗證日期：2026-03-07 | OpenClaw 2026.3.2

## 概述

OpenClaw 支援透過 ChatGPT 訂閱（OAuth）使用 OpenAI 模型，不需要 API Key。

## Provider 區別

| Provider | 認證方式 | 用途 |
|----------|---------|------|
| `openai` | API Key | 傳統 OpenAI API |
| `openai-codex` | OAuth (ChatGPT 訂閱) | **推薦** — 用訂閱額度，不另外付費 |

## 設定步驟

### 方法一：互動式設定（推薦）
```bash
openclaw configure --section model
```
流程：
1. 選擇 Local Gateway
2. 選擇 OpenAI → Codex OAuth
3. 瀏覽器開啟授權頁面 → 登入 ChatGPT
4. 授權完成 → token 自動存入 `auth-profiles.json`
5. 選擇模型（如 `gpt-5.4`）

### 方法二：CLI 指令
```bash
openclaw models auth add openai-codex
# 開啟瀏覽器授權
```

## Token 存儲

```
~/.openclaw/agents/<agentId>/agent/auth-profiles.json
```

含：
- `accessToken` — 短期 access token
- `refreshToken` — 長期 refresh token
- `expiresAt` — 過期時間
- OpenClaw 會自動 refresh

## 模型名稱格式

```
openai-codex/gpt-5.4
openai-codex/o3-pro
openai-codex/gpt-4.1
```

## 驗證

```bash
# 查看 auth 狀態
openclaw models status
# → Auth overview: openai-codex (2 profiles)

# 在 Telegram 用 /model 指令切換到 Codex GPT-5.4 測試
```

## 已知問題

- `openclaw models auth login openai-codex` — CLI 路徑可能 broken，用 `configure --section model` 代替
- `openai-codex/gpt-5.4` 在 OpenClaw 內建 catalog 可能顯示 "Unknown model"，但實際可用
- 模型設定修改是 **hot-reload**（不需重啟 gateway）
- Auth 設定修改需要 **重啟 gateway**

## 進階設定

```json
// openclaw.json 中的 model 區段
{
  "model": {
    "primary": "zai/glm-5",
    "fallbacks": ["zai/glm-4.7", "openai-codex/gpt-5.4"],
    "aliases": {
      "Codex GPT-5.4": "openai-codex/gpt-5.4"
    }
  }
}
```

Transport 選項：`auto`（預設）, `sse`, `websocket`
WebSocket warm-up：減少首次回覆延遲
Server-side compaction：減少 token 使用
