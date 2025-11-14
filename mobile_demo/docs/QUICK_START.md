# Quick Start Guide - Wazuh Android Monitoring

## Files You Need

Copy these 3 files to your Wazuh docker-compose directory:
```
ossec.conf          → Main configuration
local_decoder.xml   → Android decoder
local_rules.xml     → Android alert rules
```

## Step-by-Step Setup

### 1. Copy Config Files

```bash
# Navigate to your Wazuh docker directory
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node

# Copy the config files from your current directory
cp /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/OneRingInc_Wazuh_Rebrand/ossec.conf .
cp /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/OneRingInc_Wazuh_Rebrand/local_decoder.xml .
cp /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/OneRingInc_Wazuh_Rebrand/local_rules.xml .
```

### 2. Update docker-compose.yml

Add these volume mounts under the `wazuh.manager` service:

```yaml
services:
  wazuh.manager:
    # ... existing configuration ...
    volumes:
      # ... existing volumes ...
      
      # Add these three lines:
      - ./ossec.conf:/var/ossec/etc/ossec.conf:ro
      - ./local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml:ro
      - ./local_rules.xml:/var/ossec/etc/rules/local_rules.xml:ro
```

### 3. Restart Wazuh

```bash
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose down
docker-compose up -d
```

### 4. Verify Setup

```bash
# Check if syslog is listening
docker exec single-node-wazuh.manager-1 grep "514/UDP" /var/ossec/logs/ossec.log

# Expected output:
# wazuh-remoted: INFO: Started (pid: XXX). Listening on port 514/UDP (syslog).
```

### 5. Test with Sample Log

```bash
# Send a test Android log
echo "Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.app flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

# Wait 5 seconds, then check for alert
sleep 5
docker exec single-node-wazuh.manager-1 tail -5 /var/ossec/logs/archives/archives.json | grep "100006"
```

**Expected:** You should see a level 12 alert with description "Android app installed: com.test.app"

### 6. Configure Android Device

On your Android device, configure the syslog app:

1. **Find your Mac's IP:**
   ```bash
   ipconfig getifaddr en0
   ```
   Example output: `10.0.0.195`

2. **Configure Android syslog app:**
   - Host: `10.0.0.195` (your Mac's IP)
   - Port: `514`
   - Protocol: `UDP`

3. **Send logs from Android**

4. **Check Wazuh Dashboard:**
   - Open: https://localhost:443
   - Navigate to: Security Events / Discover
   - Filter by: `rule.id:100006`

## What You Get

✅ **JSON Archive Logging**
- All events logged to `/var/ossec/logs/archives/archives.json`

✅ **Syslog Reception**
- UDP port 514 listening for Android logs

✅ **Android Package Decoder**
- Extracts package names from PACKAGE_ADDED intents

✅ **High-Severity Alerts**
- Level 12 alerts for app installations
- Email notifications (if configured)

## Troubleshooting

### Port 514 not listening
```bash
# Check for errors
docker exec single-node-wazuh.manager-1 tail -20 /var/ossec/logs/ossec.log | grep -i error

# Restart manager
docker restart single-node-wazuh.manager-1
```

### No alerts appearing
```bash
# Check if logs are being received
docker exec single-node-wazuh.manager-1 tail -20 /var/ossec/logs/archives/archives.json

# Test decoder manually
docker exec -i single-node-wazuh.manager-1 /var/ossec/bin/wazuh-logtest << 'EOF'
android.intent.action.PACKAGE_ADDED dat=package:com.test.app
EOF
```

### Config files not loading
```bash
# Verify mounts
docker inspect single-node-wazuh.manager-1 | grep -A5 "Mounts"

# Check file permissions
ls -l ossec.conf local_decoder.xml local_rules.xml
```

## Important Notes

1. **Read-only mounts (`:ro`)** prevent accidental modifications inside the container
2. **No `<local_ip>` in syslog config** to avoid binding issues when container IP changes
3. **Custom rule ID 100006** is in the safe range (100000-120000) for local rules
4. **Level 12 alerts** trigger email notifications if SMTP is configured

## Next Steps

- Add more Android decoders for different log types
- Create rules for suspicious app installations
- Set up email notifications for high-severity alerts
- Integrate with external SIEM or log analysis tools

## Support Files

- `WAZUH_CONFIG_CHANGES.md` - Detailed documentation of all changes
- `CONFIG_SUMMARY.md` - Technical explanation of each configuration
- `docker-compose-volumes-example.yml` - Full docker-compose example

---

**Your configuration is now persistent and version-controlled!** 🎉

