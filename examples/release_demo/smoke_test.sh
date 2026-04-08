#!/usr/bin/env bash
set -euo pipefail

BASE_URL="http://localhost:${COV_PORT:-3333}"

echo "=== Step 1: Health check (AC-3) ==="
RESPONSE=$(curl -s "$BASE_URL/ping")
if [ "$RESPONSE" != "pong!" ]; then
  echo "FAIL: Expected 'pong!' but got '$RESPONSE'"
  exit 1
fi
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/ping")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
echo "PASS: /ping returned 200 with body 'pong!'"

echo ""
echo "=== Step 2: Start coverage collection (AC-4) ==="
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/cov/start" \
  -H 'Content-Type: application/json' -d '{"app_name": "release_demo"}')
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
RESPONSE=$(curl -s -X POST "$BASE_URL/cov/start" \
  -H 'Content-Type: application/json' -d '{"app_name": "release_demo"}')
if [ "$RESPONSE" != "OK" ]; then
  echo "FAIL: Expected 'OK' but got '$RESPONSE'"
  exit 1
fi
echo "PASS: /cov/start returned 200 with body 'OK'"

echo ""
echo "=== Step 3: Get coverage data (AC-5) ==="
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/cov/total/release_demo")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
RESPONSE=$(curl -s "$BASE_URL/cov/total/release_demo")
if ! echo "$RESPONSE" | grep -q '"coverage"'; then
  echo "FAIL: Response does not contain 'coverage' key: $RESPONSE"
  exit 1
fi
echo "PASS: /cov/total/release_demo returned 200 with coverage data: $RESPONSE"

echo ""
echo "=== Step 4: Check cover status (AC-6) ==="
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/cov/status")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
RESPONSE=$(curl -s "$BASE_URL/cov/status")
if ! echo "$RESPONSE" | grep -q '"already_started"'; then
  echo "FAIL: Response does not contain 'already_started': $RESPONSE"
  exit 1
fi
echo "PASS: /cov/status returned 200 with status 'already_started'"

echo ""
echo "=== All smoke tests passed! ==="
