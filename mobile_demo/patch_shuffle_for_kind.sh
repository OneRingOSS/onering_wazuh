#!/bin/bash
# Patch Wazuh Shuffle Integration to Add Host Header for Kind Cluster
# This script modifies the shuffle.py integration to add "Host: localhost" header
# Required for AI-SOC running in Kind cluster with nginx ingress

set -e

WAZUH_MANAGER="single-node-wazuh.manager-1"

echo "🔧 Patching Wazuh Shuffle Integration for Kind Cluster"
echo "======================================================="
echo ""

# Step 1: Backup original shuffle.py
echo "Step 1: Backing up original shuffle.py..."
docker exec $WAZUH_MANAGER cp /var/ossec/integrations/shuffle.py /var/ossec/integrations/shuffle.py.backup
echo "✅ Backup created at /var/ossec/integrations/shuffle.py.backup"
echo ""

# Step 2: Patch the send_msg function to add Host header
echo "Step 2: Patching send_msg function..."
docker exec $WAZUH_MANAGER bash -c "cat > /tmp/patch_shuffle.py << 'PATCH_EOF'
import sys

# Read the original file
with open('/var/ossec/integrations/shuffle.py', 'r') as f:
    content = f.read()

# Replace the headers line in send_msg function
old_headers = \"headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}\"
new_headers = \"headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}\"

if old_headers in content:
    content = content.replace(old_headers, new_headers)
    print('✅ Patched: Added Host: localhost header')
else:
    print('⚠️  Warning: Could not find headers line to patch')
    sys.exit(1)

# Write the patched file
with open('/var/ossec/integrations/shuffle.py', 'w') as f:
    f.write(content)

print('✅ Shuffle integration patched successfully')
PATCH_EOF

python3 /tmp/patch_shuffle.py
"

echo ""

# Step 3: Verify the patch
echo "Step 3: Verifying patch..."
docker exec $WAZUH_MANAGER grep -A 2 "def send_msg" /var/ossec/integrations/shuffle.py | grep -A 10 "headers ="
echo ""

# Step 4: Restart Wazuh to apply changes
echo "Step 4: Restarting Wazuh manager..."
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
echo "✅ Wazuh manager restarted"
echo ""

echo "======================================================"
echo "✅ Shuffle integration patched successfully!"
echo "======================================================"
echo ""
echo "The shuffle integration will now send 'Host: localhost' header"
echo "with all webhook requests to the AI-SOC Kind cluster."
echo ""
echo "Next: Trigger a test alert to verify the integration works:"
echo "  ./mobile_demo/trigger_ai_soc_test.sh"
echo ""

