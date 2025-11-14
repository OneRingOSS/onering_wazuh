# Wazuh Configuration Summary

## Quick Reference

### Files Created
```
ossec.conf              - Main Wazuh configuration (8.7KB)
local_decoder.xml       - Android log decoder (1.0KB)
local_rules.xml         - Android alert rules (742B)
WAZUH_CONFIG_CHANGES.md - Detailed documentation
docker-compose-volumes-example.yml - Docker compose example
```

## What Each Configuration Does

### 1. ossec.conf - Main Configuration

#### JSON Archive Logging
```xml
<logall_json>yes</logall_json>
<log_format>plain,json</log_format>
```
**Purpose:** Logs ALL events (not just alerts) to `/var/ossec/logs/archives/archives.json` in JSON format

**Use Case:** 
- Comprehensive event logging for analysis
- Integration with external tools
- Debugging and troubleshooting

#### Syslog Remote Configuration
```xml
<remote>
  <connection>syslog</connection>
  <port>514</port>
  <protocol>udp</protocol>
  <allowed-ips>0.0.0.0/0</allowed-ips>
</remote>
```
**Purpose:** Enables Wazuh to receive syslog messages via UDP on port 514

**Use Case:**
- Receive logs from Android devices
- Collect logs from network devices
- Centralized log collection

**Security Note:** `0.0.0.0/0` allows logs from any IP. For production, restrict to specific IPs:
```xml
<allowed-ips>192.168.1.0/24</allowed-ips>
```

### 2. local_decoder.xml - Android Decoder

```xml
<decoder name="android_decoder_03">
  <prematch>PACKAGE_ADDED</prematch>
  <regex>android\.intent\.action\.PACKAGE_ADDED dat=package:(\S+)</regex>
  <order>package_name</order>
</decoder>
```

**Purpose:** Parses Android package installation logs

**How it works:**
1. **Prematch:** Quickly filters logs containing "PACKAGE_ADDED"
2. **Regex:** Extracts the package name from the intent data
3. **Order:** Stores extracted value in `package_name` field

**Example Input:**
```
Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:sk.madzik.android.logcatudp flg=0x4000010 (has extras) }
```

**Extracted Data:**
```json
{
  "decoder": {"name": "android_decoder_03"},
  "data": {"package_name": "sk.madzik.android.logcatudp"}
}
```

### 3. local_rules.xml - Android Alert Rule

```xml
<rule id="100006" level="12">
  <decoded_as>android_decoder_03</decoded_as>
  <description>Android app installed: $(package_name)</description>
  <group>android_install,</group>
</rule>
```

**Purpose:** Creates high-severity alerts for Android app installations

**Rule Details:**
- **ID:** 100006 (custom rule range: 100000-120000)
- **Level:** 12 (High severity)
  - Level 0-3: Informational
  - Level 4-7: Low priority
  - Level 8-11: Medium priority
  - Level 12-15: High priority (triggers email alerts)
  - Level 16+: Critical
- **Trigger:** When `android_decoder_03` successfully decodes a log
- **Description:** Dynamic - includes the extracted package name

**Alert Output:**
```json
{
  "rule": {
    "level": 12,
    "description": "Android app installed: sk.madzik.android.logcatudp",
    "id": "100006",
    "mail": true,
    "groups": ["android", "package", "install", "android_install"]
  }
}
```

## Complete Flow

```
Android Device
    ↓ (syslog UDP:514)
Wazuh Manager (Port 514)
    ↓
Pre-decoding (extract basic fields)
    ↓
Decoding (android_decoder_03)
    ├─ Matches: PACKAGE_ADDED
    └─ Extracts: package_name
    ↓
Rule Matching (rule 100006)
    ├─ Level: 12 (High)
    └─ Description: "Android app installed: {package_name}"
    ↓
Alert Generation
    ├─ archives.json (all events)
    ├─ alerts.json (only alerts)
    └─ Wazuh Dashboard
    ↓
Email Notification (if configured)
```

## Key Benefits

1. **No Runtime Modifications:** All configs are mounted at startup
2. **Version Control:** Track changes in Git
3. **Easy Rollback:** Revert to previous versions easily
4. **Reproducible:** Same config across environments
5. **No Container Edits:** No need for `docker exec` and `sed` commands

## Next Steps

1. **Place config files** in your docker-compose directory
2. **Update docker-compose.yml** with volume mounts (see docker-compose-volumes-example.yml)
3. **Restart containers:**
   ```bash
   cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
   docker-compose down
   docker-compose up -d
   ```
4. **Verify configuration:**
   ```bash
   docker exec single-node-wazuh.manager-1 grep "514/UDP" /var/ossec/logs/ossec.log
   ```

## Testing

Send a test log:
```bash
echo "Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.app flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514
```

Check for alert:
```bash
docker exec single-node-wazuh.manager-1 tail -5 /var/ossec/logs/archives/archives.json | grep -i "100006\|android"
```

Expected: High-severity alert (level 12) with package name extracted.

