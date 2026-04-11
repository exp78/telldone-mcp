# TellDone MCP Server

Connect your [TellDone](https://telldone.app) voice notes, tasks, events, and reports to AI tools like Claude Code, Cursor, Windsurf, Codex, and any MCP-compatible client.

TellDone is a voice-first planning app. Dictate your thoughts, and AI automatically creates structured notes, tasks, events, and daily productivity reports.

Voice recording is available on **iOS** and **Apple Watch**. Android coming soon. You can also send text through MCP using `process_note` for the same AI analysis pipeline.

> Use promo code **`MCPBETA26`** after signup to get free MCP access (read & write for 30 days, then read-only for a year).

## Quick Start

### 1. Get Your Token

Sign up at [app.telldone.app](https://app.telldone.app), then go to **Settings > AI Agents (MCP)** and click **Enable**.

### 2. Connect

**Claude Code**
```bash
claude mcp add telldone --transport http \
  https://api.telldone.app/mcp/user/mcp \
  --header "Authorization: Bearer YOUR_TOKEN"
```

**Cursor** `.cursor/mcp.json`
```json
{
  "mcpServers": {
    "telldone": {
      "url": "https://api.telldone.app/mcp/user/mcp",
      "headers": { "Authorization": "Bearer YOUR_TOKEN" }
    }
  }
}
```

**Windsurf** `.codeium/windsurf/mcp_config.json`
```json
{
  "mcpServers": {
    "telldone": {
      "serverUrl": "https://api.telldone.app/mcp/user/mcp",
      "headers": { "Authorization": "Bearer YOUR_TOKEN" }
    }
  }
}
```

**Codex** `codex.json`
```json
{
  "mcpServers": {
    "telldone": {
      "type": "http",
      "url": "https://api.telldone.app/mcp/user/mcp",
      "headers": { "Authorization": "Bearer YOUR_TOKEN" }
    }
  }
}
```

**OpenClaw**
Settings > MCP Servers > Add > Name: `TellDone`, URL: `https://api.telldone.app/mcp/user/mcp`, Auth: `Bearer YOUR_TOKEN`

### 3. Start Using

Ask your AI tool things like:

- *"What did I work on today?"*
- *"Create a task: review quarterly report, high priority, deadline Friday"*
- *"Find all notes about the marketing strategy"*
- *"Mark the Figma task as done"*
- *"Create an event: team standup tomorrow at 10am, remind me 15 min before"*
- *"Process this meeting summary and extract tasks"*
- *"What events do I have next week?"*
- *"Show me my daily report from yesterday"*

## Tools (21)

### Read Tools (10)

| Tool | Description |
|------|-------------|
| `get_profile` | User profile, subscription, and usage stats |
| `get_notes` | List notes with date, tag, and text filters |
| `get_note` | Single note with linked tasks and events |
| `get_notes_full` | Bulk notes with embedded children |
| `get_tasks` | List tasks (todo/done/all) with filters |
| `get_events` | List calendar events with date range |
| `get_reports` | Daily, weekly, monthly, yearly AI reports |
| `get_tags` | User tags sorted by usage |
| `search` | Hybrid text + semantic search across all data |

### Write Tools (11)

| Tool | Description |
|------|-------------|
| `process_note` | Full pipeline: send text or audio, get AI-analyzed note + tasks + events |
| `create_note` | Quick plain text note (no AI analysis) |
| `create_task` | Task with priority, deadline, reminder, tags |
| `create_event` | Event with reminders, attendees, recurrence |
| `update_note` | Update title, summary, type, tags, priority, status |
| `update_task` | Update any field, mark done/todo, change tags |
| `update_event` | Reschedule, change status, add attendees |
| `complete_task` | Quick mark-as-done shortcut |
| `delete_note` | Soft-delete note (cascades to linked tasks and events) |
| `delete_task` | Soft-delete task |
| `delete_event` | Soft-delete event |

All write tools sync in real-time to connected mobile and web clients via WebSocket.

## Full Pipeline: `process_note`

The `process_note` tool runs the same pipeline as recording in the mobile app:

```
Text or Audio --> STT (if audio) --> LLM Analysis --> Note + Tasks + Events + Tags
```

**Text mode** (skip STT):
```json
{"name": "process_note", "arguments": {"text": "Need to buy groceries. Meeting with Katie at 3pm."}}
```

**Audio mode** (base64-encoded):
```json
{"name": "process_note", "arguments": {"audio_base64": "...", "audio_format": "m4a"}}
```

Returns immediately with `audio_id`. Results arrive via WebSocket or poll with `get_notes()`.

## Examples

### `examples/test-connection.sh`

```bash
#!/bin/bash
# Test your TellDone MCP connection
TOKEN="${1:?Usage: ./test-connection.sh YOUR_TOKEN}"
URL="https://api.telldone.app/mcp/user/mcp"

echo "=== Testing connection ==="
curl -s -X POST "$URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_profile"}}' \
  | python3 -m json.tool

echo ""
echo "=== Listing tools ==="
curl -s -X POST "$URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | python3 -c "import sys,json; tools=json.load(sys.stdin).get('result',{}).get('tools',[]); print(f'{len(tools)} tools available'); [print(f'  {t[\"name\"]}') for t in tools]"
```

### `examples/daily-summary.sh`

```bash
#!/bin/bash
# Get today's tasks and notes summary
TOKEN="${1:?Usage: ./daily-summary.sh YOUR_TOKEN}"
URL="https://api.telldone.app/mcp/user/mcp"
TODAY=$(date +%Y-%m-%d)

call() {
  curl -s -X POST "$URL" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$1"
}

echo "=== Today's Notes ($TODAY) ==="
call "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"get_notes\",\"arguments\":{\"date_from\":\"$TODAY\",\"limit\":20}}}" \
  | python3 -c "
import sys, json
r = json.loads(json.load(sys.stdin)['result']['content'][0]['text'])
for n in r: print(f'  [{n[\"type\"]}] {n[\"title\"]}')" 2>/dev/null

echo ""
echo "=== Active Tasks ==="
call '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_tasks","arguments":{"status":"todo","limit":10}}}' \
  | python3 -c "
import sys, json
r = json.loads(json.load(sys.stdin)['result']['content'][0]['text'])
for t in r: print(f'  [{t[\"priority\"]}] {t[\"title\"]}')" 2>/dev/null

echo ""
echo "=== Upcoming Events ==="
call "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"get_events\",\"arguments\":{\"date_from\":\"$TODAY\",\"limit\":5}}}" \
  | python3 -c "
import sys, json
r = json.loads(json.load(sys.stdin)['result']['content'][0]['text'])
for e in r: print(f'  {e[\"start_at\"][:16]} {e[\"title\"]}')" 2>/dev/null
```

### `examples/create-task.sh`

```bash
#!/bin/bash
# Create a task via MCP
TOKEN="${1:?Usage: ./create-task.sh YOUR_TOKEN}"
TITLE="${2:?Usage: ./create-task.sh YOUR_TOKEN 'Task title'}"
PRIORITY="${3:-medium}"

curl -s -X POST "https://api.telldone.app/mcp/user/mcp" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"create_task\",\"arguments\":{\"title\":\"$TITLE\",\"priority\":\"$PRIORITY\"}}}" \
  | python3 -m json.tool
```

## Plans and Access

| Plan | MCP Access | Read | Write | Price |
|------|-----------|------|-------|-------|
| Free | -- | -- | -- | $0 |
| Basic | -- | -- | -- | $4.99/mo |
| **Pro** | **Read & Write** | **10 tools** | **11 tools** | **$11.99/mo** |
| **Ultra** | **Read & Write** | **10 tools** | **11 tools** | **$24.99/mo** |

Pro and Ultra have the same MCP tools. Ultra has higher quotas (unlimited notes, 1500 STT min/mo, 300 uploads/day).

## Authentication

Every request requires a Bearer token in the `Authorization` header. Tokens are generated in the web app settings.

- **Regenerate**: Settings > AI Agents > Regenerate (old token revoked instantly)
- **Disable**: Settings > AI Agents > Disable (token deleted)
- **Rate limit**: 5 requests/second

## Transport

MCP Streamable HTTP (stateless). Each request is independent.

```
POST https://api.telldone.app/mcp/user/mcp
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
```

## Links

- **App**: [app.telldone.app](https://app.telldone.app)
- **Website**: [telldone.app](https://telldone.app)
- **Docs**: [docs.telldone.app](https://docs.telldone.app)
- **iOS App**: [App Store](https://apps.apple.com/app/telldone/id6742044622)
