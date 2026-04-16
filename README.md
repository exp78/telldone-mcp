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
| `get_profile` | Returns the authenticated user's profile including display name, email, locale, timezone, subscription plan, and usage statistics (total notes, tasks, events). Use this to check account status or quota. |
| `get_notes` | Lists voice notes with optional filters: `date_from`/`date_to` (ISO 8601), `tag` (string), `type` (task/idea/info/status/meeting/event/reflection), `search` (text query), `limit` (default 20, max 100), `offset`. Returns note metadata without full body — use `get_note` for details. |
| `get_note` | Returns a single note by UUID `note_id`, including full transcription, AI summary, and all linked child tasks and events. Use when you need complete note content after finding it via `get_notes` or `search`. |
| `get_notes_full` | Bulk retrieval of notes with embedded children (tasks + events). Same filters as `get_notes`. Use instead of calling `get_note` in a loop. Returns larger payloads — set `limit` appropriately. |
| `get_tasks` | Lists tasks with filters: `status` (todo/done/all, default: todo), `tag`, `priority` (low/medium/high), `date_from`/`date_to` for deadline range, `limit`, `offset`. Returns title, priority, deadline, reminder_at, tags, completion status. |
| `get_events` | Lists calendar events with `date_from`/`date_to` range filters, `status` (confirmed/tentative/cancelled), `limit`, `offset`. Returns event title, start/end times, location, attendees, and reminders. |
| `get_reports` | Returns AI-generated productivity reports. Filter by `period` (daily/weekly/monthly/yearly) and `date_from`/`date_to`. Reports summarize completed tasks, patterns, and productivity insights. |
| `get_tags` | Returns all user-defined tags sorted by usage frequency (most used first). No parameters. Use to discover available tags before filtering notes or tasks. |
| `search` | Hybrid text + semantic search across notes, tasks, and events. Parameter: `query` (string). Combines keyword matching with vector similarity for relevant results even with different wording. Returns mixed result types with relevance scores. |

### Write Tools (11)

| Tool | Description |
|------|-------------|
| `process_note` | Runs the full AI analysis pipeline on text or audio input — identical to recording a voice note in the mobile app. Accepts `text` (string) or `audio_base64` + `audio_format` (m4a/wav/mp3). AI extracts structured note + tasks + events + tags. Returns immediately with `audio_id`; results arrive asynchronously. Poll with `get_notes()` to retrieve processed output. |
| `create_note` | Creates a plain text note without AI analysis. Parameters: `title` (required), `summary`, `type` (task/idea/info/status/meeting/event/reflection), `tags` (comma-separated). Use when you want to store structured text directly without LLM processing. |
| `create_task` | Creates a task with `title` (required), `description`, `priority` (low/medium/high, default: medium), `deadline` (ISO 8601 date), `reminder_at` (ISO 8601 datetime), `tags` (comma-separated). Task is created with status "todo". Syncs to mobile app in real-time. |
| `create_event` | Creates a calendar event with `title` (required), `start_at`/`end_at` (ISO 8601 datetime), `location`, `attendees` (comma-separated), `reminder_minutes` (integer), `recurrence` (rrule string), `status` (confirmed/tentative). |
| `update_note` | Updates note fields by `note_id` (UUID, required). Optional: `title`, `summary`, `type`, `tags`, `priority`, `status`. Only provided fields are changed; omitted fields remain unchanged. |
| `update_task` | Updates task fields by `task_id` (UUID, required). Optional: `title`, `description`, `priority`, `deadline`, `reminder_at`, `tags`, `status` (todo/done). Use `complete_task` as a shortcut for marking done. |
| `update_event` | Updates event fields by `event_id` (UUID, required). Optional: `title`, `start_at`, `end_at`, `location`, `attendees`, `status` (confirmed/tentative/cancelled), `reminder_minutes`. |
| `complete_task` | Marks a task as done by `task_id` (UUID). Shortcut for `update_task` with `status: "done"`. Records completion timestamp and source ("mcp"). |
| `delete_note` | Soft-deletes a note by `note_id` (UUID). Cascades to all linked child tasks and events — they are also soft-deleted. Reversible from the web app. |
| `delete_task` | Soft-deletes a task by `task_id` (UUID). Does not affect the parent note. Reversible from the web app. |
| `delete_event` | Soft-deletes an event by `event_id` (UUID). Does not affect the parent note. Reversible from the web app. |

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
