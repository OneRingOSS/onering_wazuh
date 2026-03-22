#!/bin/bash
# Trigger AI-SOC Integration Test
# This script updates Wazuh configuration to point to AI-SOC and triggers a test alert

set -e

WAZUH_DOCKER_PATH="${1:-/Users/satheesh/Documents/projects/wazuh-docker/single-node}"
WAZUH_MANAGER="single-node-wazuh.manager-1"
AI_SOC_URL="http://host.docker.internal:8080/api/threats/ingest/wazuh"

echo "🚀 AI-SOC Integration Test"
echo "=========================="
echo ""
echo "AI-SOC Endpoint: $AI_SOC_URL"
echo "Wazuh Docker Path: $WAZUH_DOCKER_PATH"
echo ""

# Step 1: Update configuration in docker-compose directory
echo "Step 1: Updating Wazuh configuration..."
echo "---------------------------------------"
cd "$WAZUH_DOCKER_PATH"

# Backup existing config
if [ ! -f ossec.conf.backup ]; then
    cp ossec.conf ossec.conf.backup
    echo "✅ Backed up original ossec.conf"
fi

# Copy new config
cp /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh/mobile_demo/ossec.conf ./ossec.conf
echo "✅ Configuration updated in $WAZUH_DOCKER_PATH/ossec.conf"
echo ""

# Step 2: Restart Wazuh manager to apply changes
echo "Step 2: Restarting Wazuh manager..."
echo "-----------------------------------"
docker-compose restart wazuh.manager
echo "✅ Wazuh manager restarted"
echo ""

# Step 3: Wait for Wazuh to be ready
echo "Step 3: Waiting for Wazuh to be ready..."
echo "-----------------------------------------"
sleep 15
echo "✅ Wazuh should be ready"
echo ""

# Step 4: Verify integration is loaded
echo "Step 4: Verifying integration configuration..."
echo "-----------------------------------------------"
docker exec $WAZUH_MANAGER grep -A 6 "<integration>" /var/ossec/etc/ossec.conf | grep -A 1 "hook_url"
echo ""

# Step 5: Check integration status in logs
echo "Step 5: Checking integration status..."
echo "---------------------------------------"
sleep 5
docker exec $WAZUH_MANAGER grep -i "shuffle\|integration" /var/ossec/logs/ossec.log | tail -5
echo ""

# Step 6: Trigger test alert
echo "Step 6: Triggering test alert..."
echo "---------------------------------"
TEST_PACKAGE="com.malicious.aisoc.test"
echo "Package: $TEST_PACKAGE"
echo ""

echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:$TEST_PACKAGE flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

echo "✅ Test alert sent to Wazuh"
echo ""

# Step 7: Wait for processing
echo "Step 7: Waiting for alert processing..."
echo "----------------------------------------"
echo "Waiting 10 seconds for Wazuh to process and forward..."
sleep 10
echo ""

# Step 8: Check Wazuh alert
echo "Step 8: Verifying alert in Wazuh..."
echo "------------------------------------"
ALERT=$(docker exec $WAZUH_MANAGER tail -50 /var/ossec/logs/alerts/alerts.json | grep "$TEST_PACKAGE" | tail -1)

if [ -n "$ALERT" ]; then
    echo "✅ Alert found in Wazuh:"
    echo "$ALERT" | python3 -m json.tool | head -20
    echo ""
    
    # Extract alert details
    RULE_ID=$(echo "$ALERT" | python3 -c "import sys, json; print(json.load(sys.stdin)['rule']['id'])" 2>/dev/null || echo "unknown")
    LEVEL=$(echo "$ALERT" | python3 -c "import sys, json; print(json.load(sys.stdin)['rule']['level'])" 2>/dev/null || echo "unknown")
    
    echo "Alert Details:"
    echo "  Rule ID: $RULE_ID"
    echo "  Level: $LEVEL"
    echo "  Package: $TEST_PACKAGE"
    echo ""
else
    echo "❌ Alert not found in Wazuh"
    echo "This may indicate the rule didn't trigger"
    echo ""
fi

# Step 9: Check integration forwarding
echo "Step 9: Checking integration forwarding..."
echo "-------------------------------------------"
INTEGRATION_LOG=$(docker exec $WAZUH_MANAGER tail -20 /var/ossec/logs/integrations.log 2>/dev/null || echo "")

if [ -n "$INTEGRATION_LOG" ]; then
    echo "Integration log:"
    echo "$INTEGRATION_LOG"
    echo ""
    
    if echo "$INTEGRATION_LOG" | grep -q "$AI_SOC_URL"; then
        echo "✅ Integration attempted to forward to AI-SOC"
    else
        echo "⚠️  No forwarding attempt found in integration log"
    fi
else
    echo "⚠️  Integration log is empty"
fi
echo ""

# Step 10: Check for errors
echo "Step 10: Checking for errors..."
echo "--------------------------------"
ERRORS=$(docker exec $WAZUH_MANAGER grep -i "shuffle\|integration" /var/ossec/logs/ossec.log | grep -i "error" | tail -5)

if [ -n "$ERRORS" ]; then
    echo "⚠️  Errors found:"
    echo "$ERRORS"
    echo ""
    
    if echo "$ERRORS" | grep -q "Connection refused"; then
        echo "❌ Connection refused - AI-SOC endpoint may not be accessible"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Verify AI-SOC is running: curl http://localhost:8080/health"
        echo "  2. Check if port 8080 is accessible from Docker: docker exec $WAZUH_MANAGER curl -v http://host.docker.internal:8080/health"
        echo "  3. Verify AI-SOC logs for incoming requests"
    fi
else
    echo "✅ No errors found"
fi
echo ""

# Summary
echo "=========================="
echo "📊 Test Summary"
echo "=========================="
echo ""
echo "Next Steps:"
echo "  1. Check your AI-SOC logs for incoming webhook POST"
echo "  2. Verify AI-SOC returned 202 Accepted"
echo "  3. Check AI-SOC created ThreatSignal from the alert"
echo ""
echo "AI-SOC Endpoint: $AI_SOC_URL"
echo "Test Package: $TEST_PACKAGE"
echo ""
echo "To check AI-SOC logs, run:"
echo "  kubectl logs -l app=ai-soc-agent --tail=50"
echo "  # or your specific command to view AI-SOC logs"
echo ""

