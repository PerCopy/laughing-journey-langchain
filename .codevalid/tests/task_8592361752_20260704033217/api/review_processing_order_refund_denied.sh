#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TRACEPARENT="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b8-01"
ORDER_ID="ord-45632"
RESPONSE_FILE="/tmp/review_processing_order_refund_denied_${CASE_SUFFIX}.txt"
STATUS_FILE="/tmp/review_processing_order_refund_denied_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
# Use a processing fixture order referenced by the business scenario.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Customer wants refund for order ${ORDER_ID}\",\"traceparent\":\"${TRACEPARENT}\"}" \
  > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -Fx 'Refund not allowed because order is still processing' "$RESPONSE_FILE" >/dev/null
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:review_processing_order_refund_denied'

# Cleanup
# No persistent setup was created.
