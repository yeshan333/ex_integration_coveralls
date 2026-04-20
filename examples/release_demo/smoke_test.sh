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
echo "=== Step 2b: Exercise application code to generate non-zero coverage ==="
# Call business-logic functions via the release's remote_eval to ensure lines are hit.
RELEASE_BIN="_build/prod/rel/release_demo/bin/release_demo"
if [ -x "$RELEASE_BIN" ]; then
  "$RELEASE_BIN" eval 'ReleaseDemo.hello(); ReleaseDemo.add(1,2); ReleaseDemo.greet("world"); ReleaseDemo.square(3)' 2>/dev/null || true
  "$RELEASE_BIN" eval 'DepLib.multiply(2,3); DepLib.reverse_string("abc"); DepLib.factorial(5)' 2>/dev/null || true
fi
echo "PASS: Exercised application code"

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
# Verify coverage is non-zero
COVERAGE=$(echo "$RESPONSE" | grep -o '"coverage":[0-9.]*' | grep -o '[0-9.]*$')
if [ -z "$COVERAGE" ] || [ "$COVERAGE" = "0" ]; then
  echo "FAIL: Expected non-zero coverage but got: $RESPONSE"
  exit 1
fi
echo "PASS: /cov/total/release_demo returned 200 with non-zero coverage ($COVERAGE%): $RESPONSE"

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
echo "=========================================="
echo "=== Multi-app coverage (dep_apps)      ==="
echo "=========================================="

echo ""
echo "=== Step 5: Start coverage with dep_apps ==="
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/cov/start" \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "release_demo", "dep_apps": ["dep_lib"]}')
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
RESPONSE=$(curl -s -X POST "$BASE_URL/cov/start" \
  -H 'Content-Type: application/json' \
  -d '{"app_name": "release_demo", "dep_apps": ["dep_lib"]}')
if [ "$RESPONSE" != "OK" ]; then
  echo "FAIL: Expected 'OK' but got '$RESPONSE'"
  exit 1
fi
echo "PASS: /cov/start with dep_apps returned 200 with body 'OK'"

echo ""
echo "=== Step 5b: Exercise code from both apps for non-zero coverage ==="
if [ -x "$RELEASE_BIN" ]; then
  "$RELEASE_BIN" eval 'ReleaseDemo.hello(); ReleaseDemo.add(2,3); ReleaseDemo.greet("test"); ReleaseDemo.square(4)' 2>/dev/null || true
  "$RELEASE_BIN" eval 'DepLib.multiply(3,4); DepLib.reverse_string("hello"); DepLib.factorial(3)' 2>/dev/null || true
fi
echo "PASS: Exercised both apps' code"

echo ""
echo "=== Step 6: Get total coverage with dep_apps ==="
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/cov/total/release_demo?dep_apps=dep_lib")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
RESPONSE=$(curl -s "$BASE_URL/cov/total/release_demo?dep_apps=dep_lib")
if ! echo "$RESPONSE" | grep -q '"coverage"'; then
  echo "FAIL: Response does not contain 'coverage' key: $RESPONSE"
  exit 1
fi
# Verify multi-app coverage is non-zero
COVERAGE=$(echo "$RESPONSE" | grep -o '"coverage":[0-9.]*' | grep -o '[0-9.]*$')
if [ -z "$COVERAGE" ] || [ "$COVERAGE" = "0" ]; then
  echo "FAIL: Expected non-zero multi-app coverage but got: $RESPONSE"
  exit 1
fi
echo "PASS: /cov/total with dep_apps returned 200 with non-zero coverage ($COVERAGE%): $RESPONSE"

echo ""
echo "=== Step 7: Get coverage report with dep_apps ==="
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/cov/report/release_demo?dep_apps=dep_lib")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: Expected HTTP 200 but got $HTTP_CODE"
  exit 1
fi
RESPONSE=$(curl -s "$BASE_URL/cov/report/release_demo?dep_apps=dep_lib")
if ! echo "$RESPONSE" | grep -q '"files"'; then
  echo "FAIL: Response does not contain 'files' key: $RESPONSE"
  exit 1
fi
# Verify both apps appear in the report
if ! echo "$RESPONSE" | grep -q 'release_demo'; then
  echo "FAIL: Report does not contain release_demo files: $RESPONSE"
  exit 1
fi
if ! echo "$RESPONSE" | grep -q 'dep_lib'; then
  echo "FAIL: Report does not contain dep_lib files: $RESPONSE"
  exit 1
fi
echo "PASS: /cov/report with dep_apps returned 200 with files from both apps"

echo ""
echo "=== All smoke tests passed! ==="
