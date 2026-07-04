#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TRACEPARENT="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba903b6-01"
ORDER_ID="ord-22334"
RESPONSE_FILE="/tmp/callbacks_optional_configuration_${CASE_SUFFIX}.txt"
STATUS_FILE="/tmp/callbacks_optional_configuration_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
# Exercise the public API without providing callbacks.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Need refund for order ${ORDER_ID}\",\"traceparent\":\"${TRACEPARENT}\"}" \
  > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -Fx 'Refund successful' "$RESPONSE_FILE" >/dev/null
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:callbacks_optional_configuration'

# Cleanup
# No persistent setup was created.
