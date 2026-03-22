#!/bin/bash
# Patch Wazuh Shuffle Integration to Send Raw Alert Payload
# This script modifies shuffle.py to send the raw Wazuh alert instead of wrapping it

set -e

WAZUH_MANAGER="single-node-wazuh.manager-1"

echo "🔧 Patching Shuffle Integration for Raw Payload"
echo "================================================"
echo ""

# Step 1: Backup (if not already backed up)
echo "Step 1: Ensuring backup exists..."
docker exec $WAZUH_MANAGER bash -c "
if [ ! -f /var/ossec/integrations/shuffle.py.original ]; then
    cp /var/ossec/integrations/shuffle.py /var/ossec/integrations/shuffle.py.original
    echo '✅ Created original backup'
else
    echo '✅ Backup already exists'
fi
"
echo ""

# Step 2: Patch the generate_msg function to send raw alert
echo "Step 2: Patching generate_msg function..."
docker exec $WAZUH_MANAGER bash -c "cat > /tmp/patch_shuffle_raw.py << 'PATCH_EOF'
import sys

# Read the original file
with open('/var/ossec/integrations/shuffle.py', 'r') as f:
    lines = f.readlines()

# Find and replace the generate_msg function
new_lines = []
in_generate_msg = False
skip_until_return = False
indent_level = 0

for i, line in enumerate(lines):
    # Detect function start
    if 'def generate_msg(alert: any, options: any) -> str:' in line:
        in_generate_msg = True
        new_lines.append(line)
        continue
    
    # If we're in generate_msg, replace the implementation
    if in_generate_msg:
        # Keep the docstring
        if '\"\"\"' in line and not skip_until_return:
            new_lines.append(line)
            # Check if this is the closing docstring
            if line.count('\"\"\"') == 2 or (i > 0 and '\"\"\"' in lines[i-1]):
                skip_until_return = True
                # Add our new implementation after docstring
                new_lines.append('    # Filter the alert\n')
                new_lines.append('    if not filter_msg(alert):\n')
                new_lines.append('        print(\\'Skipping rule %s\\' % alert[\\'rule\\'][\\'id\\'])\n')
                new_lines.append('        return \\'\\'\n')
                new_lines.append('\n')
                new_lines.append('    # Send raw Wazuh alert for AI-SOC compatibility\n')
                new_lines.append('    # AI-SOC expects the unmodified Wazuh alert JSON\n')
                new_lines.append('    return json.dumps(alert)\n')
                new_lines.append('\n')
            continue
        
        # Skip old implementation until we find the next function
        if skip_until_return:
            # Check if we've reached the next function definition
            if line.startswith('def ') and 'generate_msg' not in line:
                in_generate_msg = False
                skip_until_return = False
                new_lines.append(line)
            # Skip the old implementation
            continue
        else:
            new_lines.append(line)
    else:
        new_lines.append(line)

# Write the patched file
with open('/var/ossec/integrations/shuffle.py', 'w') as f:
    f.writelines(new_lines)

print('✅ Shuffle integration patched to send raw alert payload')
PATCH_EOF

python3 /tmp/patch_shuffle_raw.py
"

echo ""

# Step 3: Verify the patch
echo "Step 3: Verifying patch..."
docker exec $WAZUH_MANAGER grep -A 10 "def generate_msg" /var/ossec/integrations/shuffle.py | head -20
echo ""

# Step 4: Restart Wazuh
echo "Step 4: Restarting Wazuh manager..."
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
echo "✅ Wazuh manager restarted"
echo ""

echo "================================================"
echo "✅ Shuffle integration patched successfully!"
echo "================================================"
echo ""
echo "The shuffle integration will now send the raw Wazuh alert"
echo "instead of wrapping it in a custom format."
echo ""
echo "Next: Trigger a test alert:"
echo "  echo 'emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.raw flg=0x4000010 (has extras) }' | nc -u -w1 localhost 514"
echo ""
echo "Then check AI-SOC logs:"
echo "  kubectl logs -n soc-agent-demo -l app=soc-backend --tail=20"
echo ""

