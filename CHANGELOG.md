# Changelog

All notable changes to the TellDone MCP Server integration surface.

## 1.1.0 — 2026-04-23

### Added

- **`transcript` parameter on `create_note` and `update_note`.** Lets LLM clients (Claude Desktop, Cursor, Windsurf, Codex, OpenClaw, etc.) store long-form note bodies directly via MCP. Previously the only text field was `summary`, hard-capped at 1000 chars for report-prompt safety, which forced callers to truncate content.
  - Limit is plan-based (`subscription_plans.max_text_length`): **Free 2 000 / Basic 8 000 / Pro 20 000 / Ultra 50 000** chars.
  - Mirrors the audio pipeline's design: short `summary` for reports + long `transcript` for the body.
  - `transcript` is never included in report LLM prompts — only `summary` is, so large transcripts do not affect report cost or latency.
  - `update_note` accepts a single-space `" "` to clear the field (same convention as `summary`).
  - See the new **Note Fields** section in `README.md` for the full contract and examples.

### Improved

- **Summary overflow error now hints at transcript.** When `summary` exceeds 1000 chars, the returned error is:
  ```
  summary too long (max 1000 chars, got N). For long-form content use the 'transcript' parameter (plan-based limit).
  ```
  This helps LLM clients self-correct without human intervention.

- **Better docstrings on `create_note` / `update_note`.** The FIELD ROLES block now explicitly explains which field goes into report prompts (`summary`) vs which is safe to be long (`transcript`).

### Backward compatibility

Fully backward-compatible. No migration required.

- `transcript` is an optional parameter (default `""`). Old clients calling `create_note(title, summary, tags, type)` continue to work unchanged — `notes.transcript` is stored as `NULL`.
- Response shapes unchanged. `get_note` already returned `transcript` (usually `null` for MCP-created notes before this change; can now be populated).
- `get_notes` (list) never included `transcript` in its `SELECT` — response payloads for list endpoints are unchanged.
- Error JSON envelope unchanged (`{"error": "..."}`). Only the text within for the summary-overflow case is extended; substring-match parsers on `"summary too long"` continue to work.

### Docs

- `README.md` — new **Note Fields: title, summary, transcript** section.
- Upstream server docs for technical writers: `docs/notes-field-model.md` on the TellDone server repo.

---

## 1.0.0 — 2026-04-17

Initial public release of the TellDone MCP Server integration.

- 21 tools: 10 read + 11 write.
- MCP Streamable HTTP transport at `https://api.telldone.app/mcp/user/mcp`.
- Bearer-token authentication.
- Full parity with iOS/Watch recording pipeline via `process_note`.
- Available on Pro and Ultra plans.
