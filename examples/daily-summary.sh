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
