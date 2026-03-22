# Wazuh Shuffle Integration Payload Format

## Overview

Wazuh's **native Shuffle integration** wraps the raw Wazuh alert in a custom format before sending it to the webhook. The AI-SOC agent needs to handle this format.

---

## Actual Payload Structure

When Wazuh sends an alert via the Shuffle integration, it sends this JSON structure:

```json
{
  "severity": 3,
  "pretext": "WAZUH Alert",
  "title": "Malicious Android app installed: com.test.package",
  "text": "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.package flg=0x4000010 (has extras) }",
  "rule_id": "100006",
  "timestamp": "2026-03-22T19:30:50.862+0000",
  "id": "1774207849.1724820513",
  "all_fields": {
    "timestamp": "2026-03-22T19:30:50.862+0000",
    "rule": {
      "level": 15,
      "description": "Malicious Android app installed: com.test.package",
      "id": "100006",
      "firedtimes": 1,
      "mail": true,
      "groups": ["android", "package", "installandroid_install"]
    },
    "agent": {
      "id": "000",
      "name": "wazuh.manager"
    },
    "manager": {
      "name": "wazuh.manager"
    },
    "id": "1774207849.1724820513",
    "full_log": "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.package flg=0x4000010 (has extras) }",
    "decoder": {
      "name": "android_decoder_03"
    },
    "data": {
      "package_name": "com.test.package"
    },
    "location": "192.168.65.1"
  }
}
```

---

## Field Mapping

### Top-Level Fields (Shuffle Wrapper)

| Field | Type | Description |
|-------|------|-------------|
| `severity` | integer | Shuffle severity: 1 (low), 2 (medium), 3 (high) |
| `pretext` | string | Always `"WAZUH Alert"` |
| `title` | string | Alert description from `rule.description` |
| `text` | string | Full log message |
| `rule_id` | string | Wazuh rule ID (e.g., `"100006"`) |
| `timestamp` | string | ISO-8601 timestamp |
| `id` | string | Wazuh alert ID |
| **`all_fields`** | object | **The complete raw Wazuh alert** |

### Nested Fields (in `all_fields`)

The `all_fields` object contains the **complete original Wazuh alert** with all the fields specified in `Wazuh-Webhook-Payload-Spec.md`.

---

## Severity Mapping

Wazuh Shuffle integration maps `rule.level` to `severity`:

```python
level = alert['rule']['level']

if level <= 4:
    severity = 1      # Low
elif level >= 5 and level <= 7:
    severity = 2      # Medium
else:
    severity = 3      # High (level >= 8)
```

For our Android alerts (rule 100006, level 15):
- **severity = 3** (High)

---

## AI-SOC Agent Changes Required

The AI-SOC `/api/threats/ingest/wazuh` endpoint needs to:

### Option 1: Extract from `all_fields` (Recommended)

```python
@app.post("/api/threats/ingest/wazuh")
async def ingest_wazuh_alert(request: Request):
    payload = await request.json()
    
    # Check if this is a Shuffle-wrapped payload
    if "all_fields" in payload:
        # Extract the raw Wazuh alert from the wrapper
        wazuh_alert = payload["all_fields"]
    else:
        # Direct Wazuh alert (for future compatibility)
        wazuh_alert = payload
    
    # Now process wazuh_alert as per the spec
    # ... existing validation and processing logic ...
```

### Option 2: Accept Both Formats

Update the validation to accept either:
1. **Shuffle format**: Has `all_fields` containing the raw alert
2. **Direct format**: Raw Wazuh alert (for future use)

---

## Example: Extracting Required Fields

```python
# If Shuffle format
if "all_fields" in payload:
    alert = payload["all_fields"]
else:
    alert = payload

# Now extract fields as per spec
alert_id = alert["id"]
timestamp = alert["timestamp"]
location = alert["location"]
full_log = alert["full_log"]
rule_id = alert["rule"]["id"]
rule_level = alert["rule"]["level"]
package_name = alert["data"]["package_name"]
# ... etc
```

---

## Test Payload

Here's a complete test payload in Shuffle format:

```json
{
  "severity": 3,
  "pretext": "WAZUH Alert",
  "title": "Malicious Android app installed: com.test.shuffle",
  "text": "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.shuffle flg=0x4000010 (has extras) }",
  "rule_id": "100006",
  "timestamp": "2026-03-22T20:00:00.000+0000",
  "id": "1774210000.123456789",
  "all_fields": {
    "timestamp": "2026-03-22T20:00:00.000+0000",
    "rule": {
      "level": 15,
      "description": "Malicious Android app installed: com.test.shuffle",
      "id": "100006",
      "firedtimes": 1,
      "mail": true,
      "groups": ["android", "package", "installandroid_install"]
    },
    "agent": {
      "id": "000",
      "name": "wazuh.manager"
    },
    "manager": {
      "name": "wazuh.manager"
    },
    "id": "1774210000.123456789",
    "full_log": "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.shuffle flg=0x4000010 (has extras) }",
    "decoder": {
      "name": "android_decoder_03"
    },
    "data": {
      "package_name": "com.test.shuffle"
    },
    "location": "192.168.65.1"
  }
}
```

---

## Verification Command

Test the AI-SOC endpoint with Shuffle format:

```bash
curl -X POST http://172.20.0.1:8080/api/threats/ingest/wazuh \
  -H "Content-Type: application/json" \
  -H "Host: localhost" \
  -d '{
    "severity": 3,
    "pretext": "WAZUH Alert",
    "title": "Malicious Android app installed: com.test.shuffle",
    "text": "emulator-5554: Test log",
    "rule_id": "100006",
    "timestamp": "2026-03-22T20:00:00.000+0000",
    "id": "test-shuffle-123",
    "all_fields": {
      "timestamp": "2026-03-22T20:00:00.000+0000",
      "rule": {
        "level": 15,
        "description": "Malicious Android app installed: com.test.shuffle",
        "id": "100006",
        "firedtimes": 1,
        "mail": true,
        "groups": ["android", "package", "installandroid_install"]
      },
      "agent": {"id": "000", "name": "wazuh.manager"},
      "manager": {"name": "wazuh.manager"},
      "id": "test-shuffle-123",
      "full_log": "emulator-5554: D/BackupManagerService( 1198): Test",
      "decoder": {"name": "android_decoder_03"},
      "data": {"package_name": "com.test.shuffle"},
      "location": "192.168.65.1"
    }
  }'
```

**Expected Response:** `202 Accepted` with ThreatSignal

---

## Summary

✅ **Keep Wazuh Shuffle integration unchanged** (standard format)  
✅ **Update AI-SOC to extract from `all_fields`**  
✅ **Maintain backward compatibility** for direct alerts  

The AI-SOC agent just needs to check for `all_fields` and extract the raw Wazuh alert from there!

