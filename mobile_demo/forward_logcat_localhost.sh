#!/bin/bash

# Wrapper script to forward Android logcat to Wazuh using localhost
# This avoids IP address changes when switching networks

# Configuration
WAZUH_HOST="127.0.0.1"  # Always use localhost
WAZUH_PORT="514"
EMULATOR_ID="${1:-emulator-5554}"  # Default to emulator-5554, or use first argument

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Path to the forward_logcat.py script (now local to the project)
SCRIPT_PATH="$SCRIPT_DIR/forward_logcat.py"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: forward_logcat.py not found at $SCRIPT_PATH"
    echo "Expected location: mobile_demo/forward_logcat.py"
    exit 1
fi

# Check if emulator is running
if ! adb devices | grep -q "$EMULATOR_ID"; then
    echo "❌ Error: Emulator $EMULATOR_ID is not running or not connected"
    echo "Available devices:"
    adb devices
    exit 1
fi

echo "🚀 Starting logcat forwarding..."
echo "   Emulator: $EMULATOR_ID"
echo "   Wazuh: $WAZUH_HOST:$WAZUH_PORT"
echo "   Press Ctrl+C to stop"
echo ""

# Run the script
python3 "$SCRIPT_PATH" "$WAZUH_HOST" "$WAZUH_PORT" "$EMULATOR_ID"

