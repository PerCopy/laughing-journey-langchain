#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TRACEPARENT="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b9-01"
ORDER_ID="ord-nonexistent"
RESPONSE_FILE="/tmp/review_nonexistent_order_${CASE_SUFFIX}.txt"
STATUS_FILE="/tmp/review_nonexistent_order_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
# Use an order id that should not exist.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Need refund for order ${ORDER_ID}\",\"traceparent\":\"${TRACEPARENT}\"}" \
  > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -Ei 'not found|order not found' "$RESPONSE_FILE" >/dev/null
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:review_nonexistent_order'

# Cleanup
# No persistent setup was created.
