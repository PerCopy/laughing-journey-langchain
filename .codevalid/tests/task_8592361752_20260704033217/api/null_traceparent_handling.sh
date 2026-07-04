#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
ORDER_ID="ord-88776"
RESPONSE_FILE="/tmp/null_traceparent_handling_${CASE_SUFFIX}.txt"
STATUS_FILE="/tmp/null_traceparent_handling_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
# Omit traceparent from the request body.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Refund request for order ${ORDER_ID}\"}" \
  > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -Fx 'Refund not allowed because order is still processing' "$RESPONSE_FILE" >/dev/null
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:null_traceparent_handling'

# Cleanup
# No persistent setup was created.
