#!/bin/bash

# OneRing Wazuh - Wave 3 Integration Test Script
# Tests AI-SOC webhook connectivity and alert forwarding

set -e

echo "🧪 Wave 3 Integration Test Suite"
echo "================================="
echo ""

# Configuration
AI_SOC_URL="${AI_SOC_URL:-http://localhost:8000/api/threats/ingest/wazuh}"
WAZUH_MANAGER="${WAZUH_MANAGER:-single-node-wazuh.manager-1}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

# Test 1: Check if Wazuh Manager is running
echo "Test 1: Wazuh Manager Status"
echo "----------------------------"
if docker ps --filter "name=$WAZUH_MANAGER" --format "{{.Names}}" | grep -q "$WAZUH_MANAGER"; then
    pass "Wazuh Manager container is running"
else
    fail "Wazuh Manager container not found"
    echo "   Expected container: $WAZUH_MANAGER"
    echo "   Run: docker ps --filter 'name=wazuh.manager'"
    exit 1
fi
echo ""

# Test 2: Check if integration is configured
echo "Test 2: Wave 3 Integration Configuration"
echo "----------------------------------------"
if docker exec "$WAZUH_MANAGER" grep -q "<integration>" /var/ossec/etc/ossec.conf 2>/dev/null; then
    pass "Integration block found in ossec.conf"
    
    # Show the configuration
    echo "   Configuration:"
    docker exec "$WAZUH_MANAGER" grep -A 6 "<integration>" /var/ossec/etc/ossec.conf | sed 's/^/   /'
else
    fail "Integration block not found in ossec.conf"
    warn "Run setup_mobile_monitoring.sh to configure Wave 3"
fi
echo ""

# Test 3: Check AI-SOC endpoint connectivity
echo "Test 3: AI-SOC Endpoint Connectivity"
echo "------------------------------------"
echo "   Testing: $AI_SOC_URL"

# Try to connect to AI-SOC
if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$AI_SOC_URL" > /tmp/wave3_test_status 2>/dev/null; then
    STATUS=$(cat /tmp/wave3_test_status)
    if [ "$STATUS" = "000" ]; then
        fail "Cannot connect to AI-SOC endpoint"
        warn "Ensure AI-SOC is running on port 8000"
        warn "If AI-SOC is in a container, check Docker networking"
    elif [ "$STATUS" = "404" ] || [ "$STATUS" = "405" ] || [ "$STATUS" = "200" ]; then
        pass "AI-SOC endpoint is reachable (HTTP $STATUS)"
    else
        warn "AI-SOC returned HTTP $STATUS (may be normal)"
    fi
else
    fail "Cannot connect to AI-SOC endpoint"
    warn "Ensure AI-SOC is running: docker ps | grep ai-soc"
fi
rm -f /tmp/wave3_test_status
echo ""

# Test 4: Send a test alert to AI-SOC
echo "Test 4: Test Alert Forwarding"
echo "-----------------------------"

# Create a sample alert matching Wazuh's format
TEST_ALERT=$(cat <<'EOF'
{
  "timestamp": "2026-03-22T00:00:00.000+0000",
  "rule": {
    "level": 15,
    "description": "Test alert from Wave 3 integration test",
    "id": "100006",
    "firedtimes": 1,
    "mail": true,
    "groups": ["android", "package", "test"]
  },
  "agent": {
    "id": "000",
    "name": "wazuh.manager"
  },
  "manager": {
    "name": "wazuh.manager"
  },
  "id": "test-wave3-001",
  "full_log": "TEST: Wave 3 integration test alert",
  "decoder": {
    "name": "android_decoder_03"
  },
  "data": {
    "package_name": "com.test.wave3"
  },
  "location": "test-script"
}
EOF
)

echo "   Sending test alert to AI-SOC..."
if curl -s -X POST "$AI_SOC_URL" \
    -H "Content-Type: application/json" \
    -d "$TEST_ALERT" \
    --max-time 10 > /tmp/wave3_response 2>&1; then
    pass "Test alert sent successfully"
    echo "   Response:"
    cat /tmp/wave3_response | head -5 | sed 's/^/   /'
else
    warn "Could not send test alert (AI-SOC may not be ready)"
    echo "   This is expected if AI-SOC is not yet running"
fi
rm -f /tmp/wave3_response
echo ""

# Test 5: Check Wazuh integration logs
echo "Test 5: Wazuh Integration Logs"
echo "------------------------------"
if docker exec "$WAZUH_MANAGER" test -f /var/ossec/logs/integrations.log 2>/dev/null; then
    echo "   Recent integration activity:"
    docker exec "$WAZUH_MANAGER" tail -10 /var/ossec/logs/integrations.log 2>/dev/null | sed 's/^/   /' || echo "   (No recent activity)"
    pass "Integration logs accessible"
else
    warn "Integration logs not found (may appear after first alert)"
fi
echo ""

# Summary
echo "================================="
echo "Test Summary"
echo "================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Ensure AI-SOC is running and ready to receive alerts"
    echo "2. Generate a real alert:"
    echo "   ./mobile_demo/forward_logcat_localhost.sh"
    echo "   adb install /path/to/app.apk"
    echo "3. Check AI-SOC dashboard for the alert"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo "Review the failures above and fix configuration"
    exit 1
fi

