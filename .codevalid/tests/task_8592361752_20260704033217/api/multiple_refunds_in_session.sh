#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TRACEPARENT_ONE="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba903b7-01"
TRACEPARENT_TWO="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba903b8-01"
TRACEPARENT_THREE="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba903b9-01"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
# Run three independent public API calls in sequence.

# When
curl -sS -o "$TMP_DIR/one.txt" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Refund order ord-11111\",\"traceparent\":\"${TRACEPARENT_ONE}\"}" \
  > "$TMP_DIR/one.status"

curl -sS -o "$TMP_DIR/two.txt" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Refund order ord-22222\",\"traceparent\":\"${TRACEPARENT_TWO}\"}" \
  > "$TMP_DIR/two.status"

curl -sS -o "$TMP_DIR/three.txt" -w '%{http_code}' \
  -X POST "$BASE_URL/invoke" \
  -H 'Content-Type: application/json' \
  -d "{\"user_input\":\"Refund order ord-33333\",\"traceparent\":\"${TRACEPARENT_THREE}\"}" \
  > "$TMP_DIR/three.status"

# Then
[ "$(cat "$TMP_DIR/one.status")" = "200" ]
[ "$(cat "$TMP_DIR/two.status")" = "200" ]
[ "$(cat "$TMP_DIR/three.status")" = "200" ]
grep -Fx 'Refund successful' "$TMP_DIR/one.txt" >/dev/null
grep -Fx 'Refund not allowed because order is still processing' "$TMP_DIR/two.txt" >/dev/null
grep -Fx 'Refund successful' "$TMP_DIR/three.txt" >/dev/null
printf '%s\n' 'CODEVALID_TEST_ASSERTION_OK:multiple_refunds_in_session'

# Cleanup
# No persistent setup was created.
