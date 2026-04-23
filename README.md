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

## Data Formats — Read This Before Parsing Output

Every tool returns JSON. The MCP wire response wraps payloads in `result.content[0].text` as a **JSON-encoded string** — parse it with `json.loads()` (or equivalent) to get the actual data.

**All datetimes, dates, and UUIDs in the decoded JSON are STRINGS, not native language types.** Do not call `.toordinal()`, `.weekday()`, or any datetime method directly on them — you will get `TypeError: 'str' has no attribute 'toordinal'`. Parse them first.

### Scalar output types

| Field shape | Wire format | Example | Parse with |
|-------------|-------------|---------|------------|
| UUID | string (lowercase hex with dashes) | `"b3f3c8a0-9a4d-4e12-9f4a-1a1b2c3d4e5f"` | use as-is |
| Datetime (timestamp) | ISO 8601 string with timezone offset | `"2026-04-18T11:30:00+00:00"` | `datetime.fromisoformat(s)` in Python; `new Date(s)` in JS |
| Date (calendar day, no time) | `YYYY-MM-DD` string | `"2026-04-18"` | `date.fromisoformat(s)` in Python |
| Boolean | `true` / `false` | `true` | native |
| Integer | JSON number | `42` | native |
| Nullable field | JSON `null` | `null` | `None` / `null` |

### Array / object output types

| Field | Wire format |
|-------|-------------|
| `tags` (on notes/tasks/events) | array of strings, OR `null` if never set, OR `[]` if cleared |
| `reminder_minutes` (events, writable field) | array of ints on input/output |
| `attendees` (events, writable field) | array of strings (names/emails) |
| `metadata` (notes) | JSON object or `null` |
| `tasks` / `events` arrays inside `get_note` / `get_notes_full` | always present, possibly empty `[]` |

### Enum values

- `priority` — `"low"`, `"medium"`, `"high"`, or `null`
- `note.type` — `"task"`, `"idea"`, `"info"`, `"status"`, `"meeting"`, `"event"`, `"reflection"`
- `note.status` — `"active"`, `"archived"` (deleted records are excluded from every read tool)
- `task.status` — `"todo"`, `"done"` (query param `status="all"` means "all not-deleted")
- `event.status` — `"confirmed"`, `"tentative"`, `"cancelled"`
- `report.type` — `"daily"`, `"weekly"`, `"monthly"`, `"yearly"`
- `source` (tasks), `completed_by` (tasks) — free-form strings: `"mcp"`, `"app"`, `"sync"`, `"audio"`, `"todoist"`, `"notion"`, etc.

### Per-tool output fields

| Tool | Returned fields (all at top level of each array item unless noted) |
|------|------|
| `get_profile` | `id` UUID, `email` str, `display_name` str\|null, `locale` str, `transcription_locale` str\|null, `timezone` str (IANA), `subscription` str, `mcp_mode` str, `created_at` ISO 8601 datetime str, `stats` {notes:int, tasks:int, events:int} |
| `get_notes` | `id` UUID, `title` str, `summary` str\|null, `type` enum, `tags` str[]\|null, `priority` enum\|null, `status` enum, `recorded_at` ISO 8601 datetime str\|null, `created_at` ISO 8601 datetime str |
| `get_note` | note fields (`id`, `title`, `summary`, `transcript` str\|null, `type`, `tags`, `priority`, `status`, `metadata` obj\|null, `created_at`) + `tasks[]` + `events[]` arrays with subset fields |
| `get_notes_full` | array of notes with `tasks[]` and `events[]` embedded (same subset as `get_note`, minus `metadata`) |
| `get_tasks` | `id` UUID, `title` str, `description` str\|null, `status` enum, `priority` enum\|null, `tags` str[]\|null, `deadline` YYYY-MM-DD str\|null, `reminder_at` ISO 8601 datetime str\|null, `completed_at` ISO 8601 datetime str\|null, `completed_by` str\|null, `source` str\|null, `created_at` ISO 8601 datetime str |
| `get_events` | `id` UUID, `title` str, `description` str\|null, `status` enum, `start_at` ISO 8601 datetime str (non-null), `end_at` ISO 8601 datetime str (non-null), `location` str\|null, `is_all_day` bool\|null, `tags` str[]\|null, `created_at` ISO 8601 datetime str. **Note:** `attendees`, `reminder_minutes`, `recurrence_rule` are writable via `create_event`/`update_event` but are NOT returned by `get_events`. |
| `get_reports` | `id` UUID, `type` enum, `period_start` YYYY-MM-DD str, `period_end` YYYY-MM-DD str, `content_md` str\|null, `created_at` ISO 8601 datetime str |
| `get_tags` | `tag` str, `usage_count` int, `is_pinned` bool, `is_manual` bool |
| `search` | `{notes: [...], tasks: [...], events: [...]}` — each item is `{id UUID, type "note"/"task"/"event", title str, detail str\|null, created_at ISO 8601 datetime str}`. All three arrays always present, possibly empty. |
| Write tools | minimal: `{id UUID, title str, status enum}` (plus `type` on notes). Do **not** expect full records — call the matching `get_*` tool if you need more fields. |
| Delete tools | `{id UUID, deleted: true}` |
| `process_note` | `{audio_id UUID, status "processing", mode "audio+stt"/"text-only", message str}` — async; final result arrives via WebSocket `note_ready` or a later `get_notes` call. |
| Any tool on error | `{error: "message"}` — always null-check for the `error` key before treating the response as a record. |

### Input parameter formats

- `note_id`, `task_id`, `event_id`, `parent_*_id` — UUID strings
- `date_from`, `date_to`, `deadline` — `YYYY-MM-DD` strings (empty string means "no filter")
- `start_at`, `end_at`, `reminder_at` — ISO 8601 datetime strings, e.g. `"2026-04-15T09:00:00Z"` or `"2026-04-15T09:00:00+00:00"`
- `tags` — comma-separated string on input (e.g. `"work,urgent"`); stored/returned as `string[]`
- `reminder_minutes`, `attendees` — comma-separated strings on input; stored/returned as arrays
- `is_all_day` — boolean on `create_event`; string `"true"`/`"false"` on `update_event`
- `recurrence_rule` — RRULE string, e.g. `"FREQ=WEEKLY;BYDAY=MO,WE,FR"`

### Parsing example (Python)

```python
import json
from datetime import datetime, date

# tools/call response → text → decode
payload = json.loads(response["result"]["content"][0]["text"])

# Check for error first
if "error" in payload:
    raise RuntimeError(payload["error"])

# Events: start_at is a STRING like "2026-04-18T11:30:00+00:00"
for e in payload:   # payload is list from get_events
    start = datetime.fromisoformat(e["start_at"])   # -> tz-aware datetime
    if e["end_at"]:
        end = datetime.fromisoformat(e["end_at"])

# Tasks: deadline is a STRING like "2026-04-18" (date only)
for t in tasks_payload:
    if t["deadline"]:
        d = date.fromisoformat(t["deadline"])
        days_left = (d - date.today()).days
```

## Note Fields: title, summary, transcript

Every note has three text fields with **different roles and different limits**. Choosing the right field matters — LLM clients (Claude Desktop, Cursor, etc.) should split content appropriately when using `create_note` or `update_note`.

| Field | Role | Limit | Included in report LLM prompts? |
|-------|------|-------|----------------------------------|
| `title` | One-line subject shown in lists, previews, push, email subjects. | 200 chars | ✅ (as list header) |
| `summary` | 1–3 sentence **teaser**. | **Hard cap 1000 chars** — product decision. | ✅ **Verbatim.** Keep it concise. |
| `transcript` | Full note **body**. Shown in detail view. | **Plan-based** (see below) | ❌ Never. Safe to be long. |

**Plan-based transcript limits** (`subscription_plans.max_text_length`):

| Plan | Max transcript chars |
|------|----------------------|
| Free | 2 000 |
| Basic | 8 000 |
| **Pro** | **20 000** |
| **Ultra** | **50 000** |
| Custom | 100 000 |

**Rule of thumb for LLM clients:**

- **Short output (notes, reminders, todos):** just `title` + `summary`. Leave `transcript` empty.
- **Long output (meeting notes, drafts, brainstorms, research dumps):** put a 1–3 sentence `summary` and the **full body in `transcript`**. Do not pack everything into summary — you'll hit the 1000-char error.

**Overflow error messages:**

- `summary too long (max 1000 chars, got N). For long-form content use the 'transcript' parameter (plan-based limit).`
- `transcript too long (max 20000 chars for pro plan, got N)`

**Correct usage example** (Claude Desktop captures a meeting):
```jsonc
create_note({
  title: "Weekly engineering sync — API versioning",
  summary: "Team agreed on semver deprecation policy with 6-month sunset window. Owner: Alex. Next sync: Thu.",
  transcript: "Full meeting transcript: Alice raised the question of how to deprecate v1...\n\n[... 5 KB of detail ...]",
  tags: "engineering,versioning,meeting"
})
```

**Why two different caps?**

- `summary` is included **verbatim** in daily/weekly/monthly report LLM prompts. If every summary could be 20 KB, report prompts would blow up in cost and latency (and risk context-window overflow for heavy users). 1000 chars was set in April 2026 after measuring prod data (median 247, max 554).
- `transcript` is **never** in report prompts — it only shows up in the UI detail view. Large transcripts cost only storage, not LLM tokens. Capping by plan prevents abuse but otherwise lets you be generous.

**Backward compatibility:** `transcript` is an optional parameter (default `""`). Old clients calling `create_note(title, summary, tags, type)` continue to work unchanged — the database stores `transcript = NULL`. No migration needed.

---

## Tools (20)

All tools include [MCP annotations](https://modelcontextprotocol.io/specification/2025-06-18/server/tools#tool-annotations) — `title`, `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint` — so MCP clients can surface the right confirmation UI. Every tool runs against the Telldone database only (`openWorldHint: false`) — the server never reaches out to external APIs.

### Read Tools (9)

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
| `create_note` | Creates a plain text note without AI analysis. Parameters: `title` (required, max 200), `summary` (max 1000 chars, concise teaser — included in report LLM prompts), `transcript` (plan-based limit, long-form body — NOT in report prompts), `type` (task/idea/info/status/meeting/event/reflection), `tags` (comma-separated, max 20). See **Note Fields** section for where to put long text. |
| `create_task` | Creates a task with `title` (required), `description`, `priority` (low/medium/high, default: medium), `deadline` (ISO 8601 date), `reminder_at` (ISO 8601 datetime), `tags` (comma-separated). Task is created with status "todo". Syncs to mobile app in real-time. |
| `create_event` | Creates a calendar event with `title` (required), `start_at`/`end_at` (ISO 8601 datetime), `location`, `attendees` (comma-separated), `reminder_minutes` (integer), `recurrence` (rrule string), `status` (confirmed/tentative). |
| `update_note` | Updates note fields by `note_id` (UUID, required). Optional: `title`, `summary` (max 1000), `transcript` (plan-based limit, long-form body), `type`, `tags`, `priority`, `status`. Only provided fields are changed; omitted fields remain unchanged. Pass `" "` (single space) for `summary` or `transcript` to clear the field. |
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
# NOTE: start_at is a STRING like '2026-04-18T11:30:00+00:00' — parse before date math
for e in r: print(f'  {e[\"start_at\"][:16]} {e[\"title\"]}')" 2>/dev/null
```

### `examples/create-task.sh`

```bash
#!/bin/bash
# Create a task via MCP
TOKEN="${1:?Usage: ./create-task.sh YOUR_TOKEN 'Task title'}"
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
| **Pro** | **Read & Write** | **9 tools** | **11 tools** | **$11.99/mo** |
| **Ultra** | **Read & Write** | **9 tools** | **11 tools** | **$24.99/mo** |

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
