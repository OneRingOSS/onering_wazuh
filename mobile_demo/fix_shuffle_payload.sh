#!/bin/bash
# Fix Shuffle Integration to Send Raw Wazuh Alert
# Uses sed to replace the generate_msg function

set -e

WAZUH_MANAGER="single-node-wazuh.manager-1"

echo "🔧 Fixing Shuffle Integration Payload Format"
echo "============================================="
echo ""

# Backup original
echo "Step 1: Creating backup..."
docker exec $WAZUH_MANAGER cp /var/ossec/integrations/shuffle.py /var/ossec/integrations/shuffle.py.bak2
echo "✅ Backup created"
echo ""

# Replace the generate_msg function
echo "Step 2: Replacing generate_msg function..."
docker exec $WAZUH_MANAGER bash -c 'cat > /tmp/new_generate_msg.txt << '\''EOF'\''
def generate_msg(alert: any, options: any) -> str:
    """Generate the JSON object with the message to be send

    Parameters
    ----------
    alert : any
        JSON alert object.
    options: any
        JSON options object.

    Returns
    -------

    msg: str
        The JSON message to send
    """
    # Filter the alert
    if not filter_msg(alert):
        print("Skipping rule %s" % alert["rule"]["id"])
        return ""

    # Send raw Wazuh alert for AI-SOC compatibility
    # AI-SOC expects the unmodified Wazuh alert JSON
    return json.dumps(alert)
EOF
'

# Use Python to replace the function
docker exec $WAZUH_MANAGER python3 << 'PYTHON_EOF'
import re

# Read the file
with open("/var/ossec/integrations/shuffle.py", "r") as f:
    content = f.read()

# Read the new function
with open("/tmp/new_generate_msg.txt", "r") as f:
    new_function = f.read()

# Pattern to match the entire generate_msg function
# Match from "def generate_msg" to the next "def " at the start of a line
pattern = r'def generate_msg\(alert: any, options: any\) -> str:.*?(?=\ndef [a-z_]+\()'

# Replace the function
new_content = re.sub(pattern, new_function + "\n", content, flags=re.DOTALL)

# Write back
with open("/var/ossec/integrations/shuffle.py", "w") as f:
    f.write(new_content)

print("✅ Function replaced successfully")
PYTHON_EOF

echo ""

# Verify
echo "Step 3: Verifying the change..."
docker exec $WAZUH_MANAGER grep -A 12 "def generate_msg" /var/ossec/integrations/shuffle.py | grep -A 5 "Send raw"
echo ""

# Restart
echo "Step 4: Restarting Wazuh..."
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager > /dev/null 2>&1
echo "✅ Wazuh restarted"
echo ""

echo "============================================="
echo "✅ Shuffle integration fixed!"
echo "============================================="
echo ""
echo "Now trigger a test alert:"
echo "  echo 'emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.final flg=0x4000010 (has extras) }' | nc -u -w1 localhost 514"
echo ""

