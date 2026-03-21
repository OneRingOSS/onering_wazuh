#!/bin/bash

# OneRing Wazuh - Mobile Monitoring Setup Script
# This script automates the setup of mobile monitoring for Wazuh

set -e

echo "🔧 OneRing Wazuh - Mobile Monitoring Setup"
echo "=========================================="
echo ""

# Check if running from correct directory
if [ ! -d "mobile_demo" ]; then
    echo "❌ Error: Please run this script from the onering_wazuh directory"
    echo "   cd /path/to/onering_wazuh && ./setup_mobile_monitoring.sh"
    exit 1
fi

# Get Wazuh directory from user
read -p "Enter path to your Wazuh Docker directory (e.g., /path/to/wazuh-docker/single-node): " WAZUH_DIR

# Validate directory
if [ ! -d "$WAZUH_DIR" ]; then
    echo "❌ Error: Directory not found: $WAZUH_DIR"
    exit 1
fi

if [ ! -f "$WAZUH_DIR/docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found in $WAZUH_DIR"
    exit 1
fi

echo ""
echo "📋 Configuration Summary:"
echo "   Wazuh Directory: $WAZUH_DIR"
echo "   Source: $(pwd)/mobile_demo"
echo ""

read -p "Continue with setup? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo "📦 Step 1: Copying configuration files..."

cp mobile_demo/ossec.conf "$WAZUH_DIR/"
cp mobile_demo/local_decoder.xml "$WAZUH_DIR/"
cp mobile_demo/local_rules.xml "$WAZUH_DIR/"

echo "   ✅ Configuration files copied"

echo ""
echo "📝 Step 2: Updating docker-compose.yml..."

# Check if already configured
if grep -q "Mobile monitoring configuration" "$WAZUH_DIR/docker-compose.yml"; then
    echo "   ⚠️  Mobile monitoring volumes already present in docker-compose.yml"
    echo "   Skipping volume mount update"
else
    # Backup docker-compose.yml
    cp "$WAZUH_DIR/docker-compose.yml" "$WAZUH_DIR/docker-compose.yml.backup"
    echo "   ✅ Backup created: docker-compose.yml.backup"
    
    # Add volume mounts using Python
    python3 << 'PYEOF'
import sys
with open(sys.argv[1], 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if 'wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf' in line:
        new_lines.append('      # Mobile monitoring configuration\n')
        new_lines.append('      - ./ossec.conf:/var/ossec/etc/ossec.conf:ro\n')
        new_lines.append('      - ./local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml:ro\n')
        new_lines.append('      - ./local_rules.xml:/var/ossec/etc/rules/local_rules.xml:ro\n')

with open(sys.argv[1], 'w') as f:
    f.writelines(new_lines)
PYEOF
    
    echo "   ✅ docker-compose.yml updated with volume mounts"
fi

echo ""
echo "🔄 Step 3: Restarting Wazuh containers..."

cd "$WAZUH_DIR"
docker-compose down
docker-compose up -d

echo "   ✅ Wazuh containers restarted"

echo ""
echo "⏳ Waiting 30 seconds for Wazuh to initialize..."
sleep 30

echo ""
echo "🔍 Step 4: Verifying configuration..."

# Get container name
CONTAINER=$(docker ps --filter "name=wazuh.manager" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
    echo "   ⚠️  Warning: Could not find Wazuh manager container"
else
    echo "   Container: $CONTAINER"
    
    # Check if port 514 is listening
    if docker exec "$CONTAINER" grep -q "514/UDP" /var/ossec/logs/ossec.log 2>/dev/null; then
        echo "   ✅ Port 514/UDP is listening for syslog"
    else
        echo "   ⚠️  Warning: Port 514/UDP status unclear - check logs manually"
    fi
    
    # Check if files exist
    if docker exec "$CONTAINER" test -f /var/ossec/etc/decoders/local_decoder.xml; then
        echo "   ✅ local_decoder.xml loaded"
    fi
    
    if docker exec "$CONTAINER" test -f /var/ossec/etc/rules/local_rules.xml; then
        echo "   ✅ local_rules.xml loaded"
    fi
fi

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📱 Next Steps:"
echo "   1. Start an Android emulator or connect a device"
echo "   2. Run: ./mobile_demo/forward_logcat_localhost.sh"
echo "   3. Install an app on the Android device"
echo "   4. Check alerts in Wazuh dashboard (https://localhost:443)"
echo ""
echo "🧪 Test the setup:"
echo "   echo 'BackupManagerService: Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.app flg=0x4000010 (has extras) }' | nc -u -w1 localhost 514"
echo ""
echo "📖 Documentation: mobile_demo/docs/QUICK_START.md"
echo ""

