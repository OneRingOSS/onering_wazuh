#!/bin/bash
# Apply Permanent Shuffle Patch for Kind Cluster Integration
# This script patches the shuffle.py file in the Docker volume
#
# The patch adds 'Host: localhost' header to all webhook requests, which is required
# for the Kind Nginx Ingress to properly route traffic to the AI-SOC backend.
#
# NOTE: Due to how Wazuh initializes volumes, this patch needs to be reapplied
# after container restarts. You can:
# 1. Run this script manually after each restart
# 2. Add it to your startup scripts
# 3. Create a cron job to check and reapply if needed

set -e

WAZUH_MANAGER="single-node-wazuh.manager-1"
WAZUH_DOCKER_DIR="/Users/satheesh/Documents/projects/wazuh-docker/single-node"

echo "🔧 Applying Shuffle Patch for Kind Cluster Integration"
echo "======================================================="
echo ""

# Step 1: Extract current shuffle.py from container
echo "Step 1: Extracting current shuffle.py from container..."
docker exec $WAZUH_MANAGER cat /var/ossec/integrations/shuffle.py > /tmp/shuffle_current.py
echo "✅ Extracted to /tmp/shuffle_current.py"
echo ""

# Step 2: Create patched version
echo "Step 2: Creating patched version..."
python3 << 'EOF'
# Read the current file
with open('/tmp/shuffle_current.py', 'r') as f:
    content = f.read()

# Replace the headers line in send_msg function
old_headers = "headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}"
new_headers = "headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}"

if old_headers in content:
    content = content.replace(old_headers, new_headers)
    print('✅ Patched: Added Host: localhost header')
    patched = True
elif new_headers in content:
    print('✅ Already patched - no changes needed')
    patched = False
else:
    print('⚠️  Warning: Could not find headers line to patch')
    exit(1)

# Write the patched file
with open('/tmp/shuffle_patched.py', 'w') as f:
    f.write(content)

if patched:
    print('✅ Created patched shuffle.py at /tmp/shuffle_patched.py')
else:
    print('ℹ️  Copied existing file to /tmp/shuffle_patched.py')
EOF

echo ""

# Step 3: Copy patched file to Docker volume
echo "Step 3: Copying patched file to Docker volume..."
docker cp /tmp/shuffle_patched.py $WAZUH_MANAGER:/var/ossec/integrations/shuffle.py
echo "✅ Patched file copied to container"
echo ""

# Step 4: Fix permissions
echo "Step 4: Setting correct permissions..."
docker exec $WAZUH_MANAGER chmod 750 /var/ossec/integrations/shuffle.py
docker exec $WAZUH_MANAGER chown root:wazuh /var/ossec/integrations/shuffle.py
echo "✅ Permissions set correctly"
echo ""

# Step 5: Also save to wazuh-docker directory for reference
echo "Step 5: Saving patched file to wazuh-docker directory..."
cp /tmp/shuffle_patched.py $WAZUH_DOCKER_DIR/shuffle.py
echo "✅ Saved to $WAZUH_DOCKER_DIR/shuffle.py"
echo ""

# Step 6: Verify the patch
echo "Step 6: Verifying patch..."
docker exec $WAZUH_MANAGER grep "headers = " /var/ossec/integrations/shuffle.py
echo ""

echo "======================================================"
echo "✅ Shuffle Patch Applied Successfully!"
echo "======================================================"
echo ""
echo "⚠️  IMPORTANT: This patch may need to be reapplied after"
echo "   Wazuh container restarts due to volume initialization."
echo ""
echo "📝 The patched file is saved at:"
echo "   $WAZUH_DOCKER_DIR/shuffle.py (for reference)"
echo ""
echo "🔄 After restarting the Wazuh container, run this script again:"
echo "   ./mobile_demo/apply_permanent_shuffle_patch.sh"
echo ""
echo "💡 TIP: Add this to your startup routine or create a cron job"
echo "   to automatically check and reapply the patch."
echo ""
echo "✅ Next: Trigger a test alert to verify:"
echo "   ./mobile_demo/trigger_ai_soc_test.sh"
echo ""

