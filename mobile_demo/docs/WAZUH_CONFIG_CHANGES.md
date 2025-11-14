# Wazuh Configuration Changes Summary

This document describes all the configuration changes made to the Wazuh Docker installation for Android syslog monitoring.

## Files Modified

Three configuration files have been customized and saved locally:

1. **ossec.conf** - Main Wazuh configuration
2. **local_decoder.xml** - Custom decoders for Android logs
3. **local_rules.xml** - Custom rules for Android alerts

## Changes Made

### 1. ossec.conf

**Location in container:** `/var/ossec/etc/ossec.conf`

**Changes:**
- **Enabled JSON archive logging** (line 6):
  ```xml
  <logall_json>yes</logall_json>
  ```
  - Generates `/var/ossec/logs/archives/archives.json` with all events in JSON format

- **Set dual log format** (line 24):
  ```xml
  <log_format>plain,json</log_format>
  ```
  - Logs in both plain text and JSON formats

- **Added syslog remote configuration** (lines 34-39):
  ```xml
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>0.0.0.0/0</allowed-ips>
  </remote>
  ```
  - Enables UDP syslog reception on port 514
  - Accepts logs from any IP address (0.0.0.0/0)
  - **Note:** No `<local_ip>` restriction to avoid binding issues when container IP changes

### 2. local_decoder.xml

**Location in container:** `/var/ossec/etc/decoders/local_decoder.xml`

**Changes:**
- **Added Android package installation decoder** (lines 24-28):
  ```xml
  <decoder name="android_decoder_03">
    <prematch>PACKAGE_ADDED</prematch>
    <regex>android\.intent\.action\.PACKAGE_ADDED dat=package:(\S+)</regex>
    <order>package_name</order>
  </decoder>
  ```
  - Matches Android PACKAGE_ADDED intent logs
  - Extracts the package name (e.g., `sk.madzik.android.logcatudp`)
  - Stores it in the `package_name` field

### 3. local_rules.xml

**Location in container:** `/var/ossec/etc/rules/local_rules.xml`

**Changes:**
- **Added Android app installation alert rule** (lines 21-27):
  ```xml
  <group name="android,package,install">
    <rule id="100006" level="12">
      <decoded_as>android_decoder_03</decoded_as>
      <description>Android app installed: $(package_name)</description>
      <group>android_install,</group>
    </rule>
  </group>
  ```
  - Rule ID: 100006
  - Severity Level: 12 (High - triggers email alerts)
  - Triggers when `android_decoder_03` matches a log
  - Description includes the extracted package name

## How to Mount These Files in Docker Compose

### Option 1: Mount Individual Files

Add these volume mounts to your `docker-compose.yml` under the `wazuh.manager` service:

```yaml
services:
  wazuh.manager:
    volumes:
      # Existing volumes...
      - ./ossec.conf:/var/ossec/etc/ossec.conf:ro
      - ./local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml:ro
      - ./local_rules.xml:/var/ossec/etc/rules/local_rules.xml:ro
```

### Option 2: Create a Config Directory Structure

Create a directory structure matching Wazuh's layout:

```bash
mkdir -p wazuh-config/etc/decoders
mkdir -p wazuh-config/etc/rules
cp ossec.conf wazuh-config/etc/
cp local_decoder.xml wazuh-config/etc/decoders/
cp local_rules.xml wazuh-config/etc/rules/
```

Then mount in docker-compose.yml:

```yaml
services:
  wazuh.manager:
    volumes:
      - ./wazuh-config/etc/ossec.conf:/var/ossec/etc/ossec.conf:ro
      - ./wazuh-config/etc/decoders/local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml:ro
      - ./wazuh-config/etc/rules/local_rules.xml:/var/ossec/etc/rules/local_rules.xml:ro
```

## Testing the Configuration

### 1. Verify Syslog Reception

Send a test log from your Mac:
```bash
echo "2025-11-14 11:21:47.692  1198-1198  BackupManagerService    system_process                       D  Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.example.testapp flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514
```

### 2. Check Archives

```bash
docker exec single-node-wazuh.manager-1 tail -10 /var/ossec/logs/archives/archives.json
```

### 3. Test with wazuh-logtest

```bash
docker exec -i single-node-wazuh.manager-1 /var/ossec/bin/wazuh-logtest << 'EOF'
android.intent.action.PACKAGE_ADDED dat=package:com.example.testapp
EOF
```

Expected output:
- **Phase 2:** Decoder `android_decoder_03` matches
- **Phase 3:** Rule `100006` triggers with level 12

## Android Device Configuration

Configure your Android syslog app to send logs to:
- **Host:** Your Mac's IP address (find with: `ipconfig getifaddr en0`)
- **Port:** 514
- **Protocol:** UDP

## Troubleshooting

### Port 514 binding errors
If you see "Unable to Bind port '514'" errors:
- Ensure no `<local_ip>` tag in the syslog remote configuration
- The container should bind to all interfaces (0.0.0.0)

### Logs not appearing
1. Check if syslog is listening:
   ```bash
   docker exec single-node-wazuh.manager-1 grep "514/UDP" /var/ossec/logs/ossec.log
   ```
2. Verify port is exposed:
   ```bash
   docker port single-node-wazuh.manager-1 | grep 514
   ```

### Decoder/Rule not working
1. Restart the manager after config changes:
   ```bash
   docker restart single-node-wazuh.manager-1
   ```
2. Check for XML errors in logs:
   ```bash
   docker exec single-node-wazuh.manager-1 tail -50 /var/ossec/logs/ossec.log | grep -i error
   ```

## Summary

All configuration changes are now saved locally in:
- `ossec.conf` (8.7KB)
- `local_decoder.xml` (1.0KB)
- `local_rules.xml` (742B)

These files can be version-controlled and mounted into the Wazuh manager container, eliminating the need for runtime `sed` commands.

