#!/bin/bash
# Create a task via MCP
TOKEN="${1:?Usage: ./create-task.sh YOUR_TOKEN 'Task title' [priority]}"
TITLE="${2:?Usage: ./create-task.sh YOUR_TOKEN 'Task title' [priority]}"
PRIORITY="${3:-medium}"

curl -s -X POST "https://api.telldone.app/mcp/user/mcp" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"create_task\",\"arguments\":{\"title\":\"$TITLE\",\"priority\":\"$PRIORITY\"}}}" \
  | python3 -m json.tool
