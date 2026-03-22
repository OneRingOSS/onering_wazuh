#!/bin/bash
# Quick Spec Compliance Test
# Tests the mock endpoint against the Wazuh-Webhook-Payload-Spec.md

set -e

echo "🧪 Quick Spec Compliance Test"
echo "=============================="
echo ""

# Start mock endpoint in background
echo "Starting mock endpoint..."
python3 mobile_demo/mock_ai_soc_endpoint.py 8000 > /tmp/mock_test.log 2>&1 &
MOCK_PID=$!
echo "Mock endpoint started (PID: $MOCK_PID)"

# Wait for it to start
sleep 2

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping mock endpoint..."
    kill $MOCK_PID 2>/dev/null || true
    wait $MOCK_PID 2>/dev/null || true
}
trap cleanup EXIT

# Test 1: Valid alert (should return 202)
echo ""
echo "Test 1: Valid Alert (expect 202 Accepted)"
echo "------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8000/api/threats/ingest/wazuh \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-03-21T21:17:27.771+0000",
    "rule": {
      "level": 15,
      "description": "Malicious Android app installed: com.test.spec",
      "id": "100006",
      "firedtimes": 1,
      "mail": true,
      "groups": ["android", "package", "installandroid_install"]
    },
    "agent": {"id": "000", "name": "wazuh.manager"},
    "manager": {"name": "wazuh.manager"},
    "id": "1774127847.484",
    "full_log": "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.spec flg=0x4000010 (has extras) }",
    "decoder": {"name": "android_decoder_03"},
    "data": {"package_name": "com.test.spec"},
    "location": "192.168.65.1"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "202" ]; then
    echo "✅ PASS: Got 202 Accepted"
    echo "Response body:"
    echo "$BODY" | python3 -m json.tool | head -20
    
    # Check ThreatSignal structure
    THREAT_TYPE=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('threat_type', ''))" 2>/dev/null || echo "")
    if [ "$THREAT_TYPE" = "device_compromise" ]; then
        echo "✅ PASS: threat_type = device_compromise"
    else
        echo "❌ FAIL: threat_type = $THREAT_TYPE"
    fi
    
    CUSTOMER=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('customer_name', ''))" 2>/dev/null || echo "")
    if [ "$CUSTOMER" = "SeniorFraudShield" ]; then
        echo "✅ PASS: customer_name = SeniorFraudShield"
    else
        echo "❌ FAIL: customer_name = $CUSTOMER"
    fi
else
    echo "❌ FAIL: Got HTTP $HTTP_CODE instead of 202"
    echo "$BODY"
fi

# Test 2: Invalid rule ID (should return 422)
echo ""
echo "Test 2: Invalid Rule ID (expect 422)"
echo "-------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8000/api/threats/ingest/wazuh \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-03-21T21:17:27.771+0000",
    "rule": {
      "level": 15,
      "description": "Test",
      "id": "999999",
      "firedtimes": 1,
      "groups": ["test"]
    },
    "agent": {"id": "000", "name": "wazuh.manager"},
    "manager": {"name": "wazuh.manager"},
    "id": "123",
    "full_log": "test",
    "decoder": {"name": "test"},
    "data": {"package_name": "test"},
    "location": "192.168.65.1"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "422" ]; then
    echo "✅ PASS: Got 422 Unprocessable Entity"
    echo "Error message:"
    echo "$BODY" | python3 -m json.tool
else
    echo "❌ FAIL: Got HTTP $HTTP_CODE instead of 422"
fi

# Test 3: Missing required field (should return 422)
echo ""
echo "Test 3: Missing Required Field (expect 422)"
echo "--------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8000/api/threats/ingest/wazuh \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-03-21T21:17:27.771+0000",
    "rule": {
      "level": 15,
      "description": "Test",
      "id": "100006",
      "firedtimes": 1,
      "groups": ["test"]
    },
    "agent": {"id": "000", "name": "wazuh.manager"},
    "manager": {"name": "wazuh.manager"},
    "id": "123",
    "full_log": "test",
    "decoder": {"name": "test"},
    "location": "192.168.65.1"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "422" ]; then
    echo "✅ PASS: Got 422 Unprocessable Entity"
    echo "Error message:"
    echo "$BODY" | python3 -m json.tool
else
    echo "❌ FAIL: Got HTTP $HTTP_CODE instead of 422"
fi

echo ""
echo "=============================="
echo "✅ Spec compliance tests complete!"
echo "=============================="

