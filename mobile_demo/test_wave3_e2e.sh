#!/bin/bash
#
# Wave 3 End-to-End Integration Test
#
# This script validates the complete Wave 3 alert forwarding flow:
# 1. Starts a mock AI-SOC endpoint
# 2. Sends a test alert to Wazuh
# 3. Verifies the alert was forwarded to the mock endpoint
# 4. Cleans up
#
# Usage: ./test_wave3_e2e.sh
#

# Don't exit on error - we want to run all tests
set +e

# Configuration
MOCK_PORT=8000
WAZUH_MANAGER="single-node-wazuh.manager-1"
TEST_PACKAGE="com.test.wave3.e2e"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOCK_SCRIPT="$SCRIPT_DIR/mock_ai_soc_endpoint.py"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Cleanup function
cleanup() {
    echo ""
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Stop mock server if running
    if [ ! -z "$MOCK_PID" ] && kill -0 $MOCK_PID 2>/dev/null; then
        echo "   Stopping mock AI-SOC endpoint (PID: $MOCK_PID)"
        kill $MOCK_PID 2>/dev/null || true
        wait $MOCK_PID 2>/dev/null || true
    fi
    
    echo ""
    echo "================================="
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo "================================="
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

# Main test execution
echo "🧪 Wave 3 End-to-End Integration Test"
echo "====================================="
echo ""

# Test 1: Check prerequisites
echo "Test 1: Prerequisites"
echo "---------------------"

# Check if Wazuh is running
if docker ps --filter "name=$WAZUH_MANAGER" --format '{{.Names}}' | grep -q "$WAZUH_MANAGER"; then
    pass "Wazuh Manager container is running"
else
    fail "Wazuh Manager container is not running"
    echo "   Please start Wazuh first: cd /path/to/wazuh-docker/single-node && docker-compose up -d"
    exit 1
fi

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    pass "Python 3 is available"
else
    fail "Python 3 is not installed"
    exit 1
fi

# Check if netcat is available
if command -v nc &> /dev/null; then
    pass "netcat is available"
else
    fail "netcat is not installed"
    exit 1
fi

echo ""

# Test 2: Start mock AI-SOC endpoint
echo "Test 2: Mock AI-SOC Endpoint"
echo "----------------------------"

info "Starting mock AI-SOC endpoint on port $MOCK_PORT"
python3 "$MOCK_SCRIPT" $MOCK_PORT > /tmp/mock_ai_soc.log 2>&1 &
MOCK_PID=$!

# Wait for server to start
sleep 2

if kill -0 $MOCK_PID 2>/dev/null; then
    pass "Mock AI-SOC endpoint started (PID: $MOCK_PID)"
else
    fail "Failed to start mock AI-SOC endpoint"
    cat /tmp/mock_ai_soc.log
    exit 1
fi

# Test health endpoint
if curl -s http://localhost:$MOCK_PORT/health | grep -q "healthy"; then
    pass "Mock endpoint health check successful"
else
    fail "Mock endpoint health check failed"
fi

echo ""

# Test 3: Send test alert to Wazuh
echo "Test 3: Send Test Alert"
echo "-----------------------"

info "Sending test alert for package: $TEST_PACKAGE"
echo "BackupManagerService: Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:$TEST_PACKAGE flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

if [ $? -eq 0 ]; then
    pass "Test alert sent to Wazuh"
else
    fail "Failed to send test alert"
fi

echo ""

# Test 4: Wait for alert processing
echo "Test 4: Alert Processing"
echo "------------------------"

info "Waiting 10 seconds for Wazuh to process and forward alert..."
sleep 10

echo ""

# Test 5: Verify alert in Wazuh
echo "Test 5: Verify Alert in Wazuh"
echo "------------------------------"

# Check if alert appears in Wazuh alerts.json
if docker exec $WAZUH_MANAGER tail -50 /var/ossec/logs/alerts/alerts.json | grep -q "$TEST_PACKAGE"; then
    pass "Alert found in Wazuh alerts.json"

    # Extract and display alert details
    ALERT_JSON=$(docker exec $WAZUH_MANAGER tail -50 /var/ossec/logs/alerts/alerts.json | grep "$TEST_PACKAGE" | tail -1)
    RULE_ID=$(echo "$ALERT_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('rule', {}).get('id', 'unknown'))" 2>/dev/null || echo "unknown")
    RULE_LEVEL=$(echo "$ALERT_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('rule', {}).get('level', 'unknown'))" 2>/dev/null || echo "unknown")

    info "Alert details: rule_id=$RULE_ID, level=$RULE_LEVEL"
else
    fail "Alert not found in Wazuh alerts.json"
fi

echo ""

# Test 6: Verify integration attempted forwarding
echo "Test 6: Verify Integration Forwarding"
echo "--------------------------------------"

# Check integration logs
INTEGRATION_LOG=$(docker exec $WAZUH_MANAGER tail -20 /var/ossec/logs/integrations.log 2>/dev/null || echo "")

if echo "$INTEGRATION_LOG" | grep -q "host.docker.internal:$MOCK_PORT"; then
    pass "Integration attempted to forward alert"
    info "Integration log entry found"
else
    warn "No integration log entry found (may still be processing)"
fi

# Check for errors in ossec.log
ERROR_LOG=$(docker exec $WAZUH_MANAGER grep -i "shuffle.*error" /var/ossec/logs/ossec.log | tail -5 2>/dev/null || echo "")

if [ -z "$ERROR_LOG" ]; then
    pass "No integration errors in ossec.log"
else
    # Check if it's just connection refused (expected if mock wasn't ready)
    if echo "$ERROR_LOG" | grep -q "Connection refused"; then
        warn "Connection refused error found (mock may not have been ready)"
    else
        fail "Integration errors found in ossec.log"
        echo "$ERROR_LOG"
    fi
fi

echo ""

# Test 7: Verify alert received by mock endpoint
echo "Test 7: Verify Mock Endpoint Received Alert"
echo "--------------------------------------------"

# Query the mock endpoint for received alerts
MOCK_RESPONSE=$(curl -s http://localhost:$MOCK_PORT/alerts)
ALERT_COUNT=$(echo "$MOCK_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('count', 0))" 2>/dev/null || echo "0")

if [ "$ALERT_COUNT" -gt 0 ]; then
    pass "Mock endpoint received $ALERT_COUNT alert(s)"

    # Verify the alert contains our test package
    if echo "$MOCK_RESPONSE" | grep -q "$TEST_PACKAGE"; then
        pass "Alert contains test package name: $TEST_PACKAGE"

        # Extract alert details
        info "Alert successfully forwarded from Wazuh to AI-SOC endpoint!"
    else
        fail "Alert does not contain test package name"
    fi
else
    fail "Mock endpoint did not receive any alerts"
    info "This may indicate the integration is not forwarding correctly"

    # Show integration logs for debugging
    echo ""
    echo "Integration logs:"
    docker exec $WAZUH_MANAGER tail -20 /var/ossec/logs/integrations.log 2>/dev/null || echo "No integration logs"
    echo ""
    echo "Recent ossec.log entries:"
    docker exec $WAZUH_MANAGER grep -i shuffle /var/ossec/logs/ossec.log | tail -10 2>/dev/null || echo "No shuffle logs"
fi

echo ""

# Test 8: Verify alert payload structure
echo "Test 8: Verify Alert Payload Structure"
echo "---------------------------------------"

if [ "$ALERT_COUNT" -gt 0 ]; then
    # Check for required fields in the alert
    REQUIRED_FIELDS=("rule" "timestamp" "data" "full_log")

    for field in "${REQUIRED_FIELDS[@]}"; do
        if echo "$MOCK_RESPONSE" | grep -q "\"$field\""; then
            pass "Alert contains required field: $field"
        else
            fail "Alert missing required field: $field"
        fi
    done
else
    warn "Skipping payload structure test (no alerts received)"
fi

echo ""

# Test 9: Verify ThreatSignal Response (per spec)
echo "Test 9: Verify ThreatSignal Response"
echo "-------------------------------------"

if [ "$ALERT_COUNT" -gt 0 ]; then
    # Get the first alert's threat_signal
    FIRST_ALERT=$(echo "$MOCK_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data['alerts'][0]['threat_signal'])) if data['alerts'] else print('{}')" 2>/dev/null || echo "{}")

    if [ "$FIRST_ALERT" != "{}" ]; then
        # Check ThreatSignal structure
        THREAT_FIELDS=("id" "threat_type" "customer_name" "timestamp" "metadata")

        for field in "${THREAT_FIELDS[@]}"; do
            if echo "$FIRST_ALERT" | grep -q "\"$field\""; then
                pass "ThreatSignal contains required field: $field"
            else
                fail "ThreatSignal missing required field: $field"
            fi
        done

        # Verify threat_type
        THREAT_TYPE=$(echo "$FIRST_ALERT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('threat_type', ''))" 2>/dev/null || echo "")
        if [ "$THREAT_TYPE" = "device_compromise" ]; then
            pass "ThreatSignal has correct threat_type: device_compromise"
        else
            fail "ThreatSignal has incorrect threat_type: $THREAT_TYPE"
        fi

        # Verify customer_name
        CUSTOMER=$(echo "$FIRST_ALERT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('customer_name', ''))" 2>/dev/null || echo "")
        if [ "$CUSTOMER" = "SeniorFraudShield" ]; then
            pass "ThreatSignal has correct customer_name: SeniorFraudShield"
        else
            fail "ThreatSignal has incorrect customer_name: $CUSTOMER"
        fi

        # Verify metadata fields
        METADATA_FIELDS=("rule_id" "wazuh_rule_level" "initial_severity_hint" "package_name" "source_ip" "endpoint_name")

        for field in "${METADATA_FIELDS[@]}"; do
            if echo "$FIRST_ALERT" | grep -q "\"$field\""; then
                pass "ThreatSignal.metadata contains: $field"
            else
                warn "ThreatSignal.metadata missing: $field"
            fi
        done
    else
        warn "Could not extract ThreatSignal from response"
    fi
else
    warn "Skipping ThreatSignal test (no alerts received)"
fi

echo ""

# Summary
echo "Test Summary"
echo "------------"
info "Mock AI-SOC endpoint log:"
tail -20 /tmp/mock_ai_soc.log 2>/dev/null || echo "No logs available"

echo ""

