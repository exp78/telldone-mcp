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
