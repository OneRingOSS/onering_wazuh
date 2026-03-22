#!/bin/bash
# Backup Current Working State - Wazuh → AI-SOC Integration
# This script creates a backup of all critical configuration files

set -e

BACKUP_DIR="mobile_demo/backups/checkpoint_$(date +%Y%m%d_%H%M%S)"
WAZUH_MANAGER="single-node-wazuh.manager-1"

echo "📦 Creating Backup of Current Working State"
echo "==========================================="
echo ""
echo "Backup directory: $BACKUP_DIR"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup local configuration files
echo "Step 1: Backing up local configuration files..."
cp mobile_demo/ossec.conf "$BACKUP_DIR/ossec.conf"
echo "  ✅ ossec.conf"

cp mobile_demo/patch_shuffle_for_kind.sh "$BACKUP_DIR/patch_shuffle_for_kind.sh"
echo "  ✅ patch_shuffle_for_kind.sh"

cp mobile_demo/trigger_ai_soc_test.sh "$BACKUP_DIR/trigger_ai_soc_test.sh"
echo "  ✅ trigger_ai_soc_test.sh"

cp mobile_demo/CHECKPOINT_LIVE_INTEGRATION.md "$BACKUP_DIR/CHECKPOINT_LIVE_INTEGRATION.md"
echo "  ✅ CHECKPOINT_LIVE_INTEGRATION.md"

cp mobile_demo/QUICK_REFERENCE.md "$BACKUP_DIR/QUICK_REFERENCE.md"
echo "  ✅ QUICK_REFERENCE.md"

cp mobile_demo/SHUFFLE_PAYLOAD_FORMAT.md "$BACKUP_DIR/SHUFFLE_PAYLOAD_FORMAT.md"
echo "  ✅ SHUFFLE_PAYLOAD_FORMAT.md"

echo ""

# Backup Wazuh container files
echo "Step 2: Backing up Wazuh container files..."

# Backup active ossec.conf
docker exec $WAZUH_MANAGER cat /var/ossec/etc/ossec.conf > "$BACKUP_DIR/wazuh_active_ossec.conf"
echo "  ✅ wazuh_active_ossec.conf (from container)"

# Backup patched shuffle.py
docker exec $WAZUH_MANAGER cat /var/ossec/integrations/shuffle.py > "$BACKUP_DIR/shuffle_patched.py"
echo "  ✅ shuffle_patched.py (with Host header)"

# Backup original shuffle.py if it exists
docker exec $WAZUH_MANAGER bash -c "if [ -f /var/ossec/integrations/shuffle.py.backup ]; then cat /var/ossec/integrations/shuffle.py.backup; fi" > "$BACKUP_DIR/shuffle_original.py" 2>/dev/null || echo "  ⚠️  shuffle_original.py (not found)"

# Backup recent integration logs
docker exec $WAZUH_MANAGER tail -50 /var/ossec/logs/integrations.log > "$BACKUP_DIR/integrations.log"
echo "  ✅ integrations.log (last 50 lines)"

# Backup recent alerts
docker exec $WAZUH_MANAGER tail -20 /var/ossec/logs/alerts/alerts.json > "$BACKUP_DIR/recent_alerts.json"
echo "  ✅ recent_alerts.json (last 20 alerts)"

echo ""

# Create restore script
echo "Step 3: Creating restore script..."
cat > "$BACKUP_DIR/RESTORE.sh" << 'RESTORE_EOF'
#!/bin/bash
# Restore Wazuh → AI-SOC Integration from Backup

set -e

WAZUH_MANAGER="single-node-wazuh.manager-1"
BACKUP_DIR="$(dirname "$0")"

echo "🔄 Restoring Wazuh → AI-SOC Integration"
echo "======================================="
echo ""
echo "Backup source: $BACKUP_DIR"
echo ""

# Restore ossec.conf to host
echo "Step 1: Restoring ossec.conf to host..."
cp "$BACKUP_DIR/ossec.conf" /Users/satheesh/Documents/projects/wazuh-docker/single-node/ossec.conf
echo "  ✅ Copied to wazuh-docker/single-node/ossec.conf"
echo ""

# Restart Wazuh to load config
echo "Step 2: Restarting Wazuh manager..."
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
echo "  ✅ Wazuh restarted"
echo ""

# Wait for Wazuh to start
echo "Step 3: Waiting for Wazuh to initialize..."
sleep 15
echo "  ✅ Ready"
echo ""

# Restore patched shuffle.py
echo "Step 4: Restoring patched shuffle.py..."
docker cp "$BACKUP_DIR/shuffle_patched.py" $WAZUH_MANAGER:/var/ossec/integrations/shuffle.py
echo "  ✅ Patched shuffle.py restored"
echo ""

# Restart Wazuh again to load patched integration
echo "Step 5: Final restart..."
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
echo "  ✅ Wazuh restarted with patched integration"
echo ""

# Verify
echo "Step 6: Verifying restoration..."
docker exec $WAZUH_MANAGER grep -A 6 "<integration>" /var/ossec/etc/ossec.conf | grep -q "172.20.0.1:8080" && echo "  ✅ Integration endpoint correct"
docker exec $WAZUH_MANAGER grep "headers =" /var/ossec/integrations/shuffle.py | grep -q "Host.*localhost" && echo "  ✅ Host header present"
echo ""

echo "======================================="
echo "✅ Restoration Complete!"
echo "======================================="
echo ""
echo "Test the integration with:"
echo "  cd /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh"
echo "  echo 'emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.restored flg=0x4000010 (has extras) }' | nc -u -w1 localhost 514"
echo ""
RESTORE_EOF

chmod +x "$BACKUP_DIR/RESTORE.sh"
echo "  ✅ RESTORE.sh created"
echo ""

# Create README
cat > "$BACKUP_DIR/README.md" << 'README_EOF'
# Backup - Wazuh → AI-SOC Integration

This backup contains the working state of the Wazuh → AI-SOC integration.

## Status at Backup Time
- ✅ Wazuh detecting Android package installations
- ✅ Shuffle integration forwarding to AI-SOC
- ✅ Alerts reaching AI-SOC ingress
- ✅ AI-SOC accepting Shuffle-wrapped format
- ⚠️ AI-SOC has datetime bug (not Wazuh issue)

## Files Included
- `ossec.conf` - Wazuh integration configuration
- `shuffle_patched.py` - Shuffle integration with Host header
- `shuffle_original.py` - Original Shuffle integration (backup)
- `patch_shuffle_for_kind.sh` - Script to apply Host header patch
- `trigger_ai_soc_test.sh` - Test automation script
- `CHECKPOINT_LIVE_INTEGRATION.md` - Full documentation
- `QUICK_REFERENCE.md` - Quick command reference
- `SHUFFLE_PAYLOAD_FORMAT.md` - Payload format documentation
- `integrations.log` - Recent integration activity
- `recent_alerts.json` - Recent Wazuh alerts
- `RESTORE.sh` - Automated restoration script

## How to Restore

### Automated Restoration
```bash
./RESTORE.sh
```

### Manual Restoration
See `CHECKPOINT_LIVE_INTEGRATION.md` for step-by-step instructions.

## Verification After Restore
```bash
# Check integration config
docker exec single-node-wazuh.manager-1 grep -A 6 "<integration>" /var/ossec/etc/ossec.conf

# Check Host header
docker exec single-node-wazuh.manager-1 grep "headers =" /var/ossec/integrations/shuffle.py

# Trigger test alert
echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.verify flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

# Check it was forwarded
docker exec single-node-wazuh.manager-1 tail -3 /var/ossec/logs/integrations.log

# Check ingress received it
kubectl logs -n ingress-nginx ingress-nginx-controller-589b66c8-kzp4b --tail=5 | grep "172.20.0.5"
```

## Expected Results
- Wazuh should forward alert to `http://172.20.0.1:8080/api/threats/ingest/wazuh`
- Ingress should show POST from `172.20.0.5`
- AI-SOC should return HTTP 500 (datetime bug) or HTTP 202 (if bug fixed)

---

**Backup created:** $(date)
README_EOF

echo "  ✅ README.md created"
echo ""

echo "==========================================="
echo "✅ Backup Complete!"
echo "==========================================="
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "Files backed up:"
echo "  - Configuration files (ossec.conf, scripts)"
echo "  - Patched shuffle.py with Host header"
echo "  - Documentation (checkpoint, quick reference)"
echo "  - Recent logs and alerts"
echo "  - Automated RESTORE.sh script"
echo ""
echo "To restore this state later:"
echo "  cd $BACKUP_DIR"
echo "  ./RESTORE.sh"
echo ""

