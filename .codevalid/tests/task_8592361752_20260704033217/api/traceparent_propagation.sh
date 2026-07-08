#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
WIREMOCK_URL="${WIREMOCK_URL:-http://wiremock:8080}"
TRACEPARENT="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba903b5-01"
ORDER_ID="ord-77665"
TMP_DIR="$(mktemp -d)"
MAPPING_ID=""
cleanup() {
  if [ -n "$MAPPING_ID" ]; then
    curl -fsS -X DELETE "$WIREMOCK_URL/__admin/mappings/${MAPPING_ID}" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Given: register a detection mapping (no id - WireMock auto-assigns a UUID)
cat >"$TMP_DIR/mapping.json" <<EOF
{
  "request": {
    "method": "ANY",
    "urlPathPattern": "/.*",
    "headers": {
      "traceparent": { "equalTo": "${TRACEPARENT}" }
    }
  },
  "response": {
    "status": 200,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "matched": true }
  }
}
EOF
MAPPING_RESPONSE="$(curl -fsS -X POST "$WIREMOCK_URL/__admin/mappings" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/mapping.json")"
MAPPING_ID="$(printf '%s' "$MAPPING_RESPONSE" | jq -r '.id')"

# When
curl -sS -o "$TMP_DIR/response.txt" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Refund order ${ORDER_ID}\",\"traceparent\":\"${TRACEPARENT}\"}" \
  > "$TMP_DIR/status.txt"

# Then
STATUS="$(cat "$TMP_DIR/status.txt")"
[ "$STATUS" = "200" ]
grep -Fx 'Refund successful' "$TMP_DIR/response.txt" >/dev/null
curl -fsS "$WIREMOCK_URL/__admin/requests" > "$TMP_DIR/requests.json"
grep -F "${TRACEPARENT}" "$TMP_DIR/requests.json" >/dev/null
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:traceparent_propagation'

# Cleanup
# Registered WireMock mapping is removed in the trap.
