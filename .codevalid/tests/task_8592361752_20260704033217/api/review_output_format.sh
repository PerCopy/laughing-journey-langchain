#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TRACEPARENT="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba903b4-01"
ORDER_ID="ord-33445"
RESPONSE_FILE="/tmp/review_output_format_${CASE_SUFFIX}.txt"
STATUS_FILE="/tmp/review_output_format_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
# Use a delivered fixture order so the final customer-facing response is deterministic.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Please refund order ${ORDER_ID}\",\"traceparent\":\"${TRACEPARENT}\"}" \
  > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
BODY="$(cat "$RESPONSE_FILE")"
[ "$STATUS" = "200" ]
[ "$BODY" = 'Refund successful' ]
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:review_output_format'

# Cleanup
# No persistent setup was created.
