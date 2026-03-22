# Live AI-SOC Integration Guide

## Overview

This document describes how to integrate Wazuh (running in Docker) with AI-SOC Agent (running in Kind Kubernetes cluster).

---

## Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│  Wazuh Manager      │         │  Kind Cluster        │
│  (Docker)           │         │  (Kubernetes)        │
│                     │         │                      │
│  ┌──────────────┐   │         │  ┌───────────────┐   │
│  │ Shuffle      │───┼────────>│  │ nginx ingress │   │
│  │ Integration  │   │  HTTP   │  │ :8080         │   │
│  └──────────────┘   │  POST   │  └───────┬───────┘   │
│                     │         │          │           │
│  172.20.0.1:8080    │         │  ┌───────▼───────┐   │
└─────────────────────┘         │  │ AI-SOC Agent  │   │
                                │  │ Backend       │   │
                                │  └───────────────┘   │
                                └──────────────────────┘
```

---

## Network Configuration

### Issue
- **Wazuh**: Runs in Docker Compose
- **AI-SOC**: Runs in Kind (Kubernetes in Docker)
- **Problem**: Different Docker networks, `host.docker.internal` doesn't work

### Solution
1. **IP Address**: Use `172.20.0.1:8080` (Kind cluster bridge network)
2. **Host Header**: Add `Host: localhost` header (required by nginx ingress)

---

## Setup Steps

### Step 1: Update Wazuh Integration Configuration

The integration is configured in `mobile_demo/ossec.conf`:

```xml
<integration>
  <name>shuffle</name>
  <hook_url>http://172.20.0.1:8080/api/threats/ingest/wazuh</hook_url>
  <level>8</level>
  <rule_id>100006</rule_id>
  <alert_format>json</alert_format>
</integration>
```

### Step 2: Patch Shuffle Integration for Host Header

Wazuh's shuffle integration doesn't support custom headers in `ossec.conf`, so we patch the Python script:

```bash
./mobile_demo/patch_shuffle_for_kind.sh
```

This script:
1. Backs up `/var/ossec/integrations/shuffle.py`
2. Modifies the `send_msg()` function to add `'Host': 'localhost'` header
3. Restarts Wazuh manager

**Modified line:**
```python
# Before:
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}

# After:
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}
```

### Step 3: Apply Configuration

```bash
# Copy updated config to Wazuh docker-compose directory
cp mobile_demo/ossec.conf /Users/satheesh/Documents/projects/wazuh-docker/single-node/ossec.conf

# Restart Wazuh
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
```

### Step 4: Trigger Test Alert

```bash
# Send test package installation alert
echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.live flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

# Wait for processing
sleep 10

# Check if forwarded
docker exec single-node-wazuh.manager-1 tail -5 /var/ossec/logs/integrations.log
```

### Step 5: Verify in AI-SOC

```bash
# Check AI-SOC backend logs
kubectl logs -n soc-agent-demo -l app=soc-backend --tail=50 -f

# Look for:
# - POST /api/threats/ingest/wazuh
# - 202 Accepted response
# - ThreatSignal creation
```

---

## Verification

### 1. Check Wazuh Integration Log

```bash
docker exec single-node-wazuh.manager-1 tail -10 /var/ossec/logs/integrations.log
```

**Expected output:**
```
/tmp/shuffle-XXXXXXXXX-XXXXXXXXX.alert  http://172.20.0.1:8080/api/threats/ingest/wazuh
```

### 2. Check Wazuh Errors

```bash
docker exec single-node-wazuh.manager-1 grep -i "shuffle.*error" /var/ossec/logs/ossec.log | tail -5
```

**Expected:** No recent errors (old errors from previous tests are OK)

### 3. Test Connectivity

```bash
# Test if Wazuh can reach AI-SOC
docker exec single-node-wazuh.manager-1 curl -v \
  -X POST http://172.20.0.1:8080/api/threats/ingest/wazuh \
  -H "Content-Type: application/json" \
  -H "Host: localhost" \
  -d '{"test": "connectivity"}'
```

**Expected:** HTTP 202 Accepted or 422 (validation error is OK, means endpoint is reachable)

---

## Payload Structure

Wazuh sends this JSON payload to AI-SOC:

```json
{
  "timestamp": "2026-03-22T19:28:51.862+0000",
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
  "full_log": "emulator-5554: D/BackupManagerService( 1198): ...",
  "decoder": {
    "name": "android_decoder_03"
  },
  "data": {
    "package_name": "com.test.package"
  },
  "location": "192.168.65.1"
}
```

---

## Expected AI-SOC Response

Per `Wazuh-Webhook-Payload-Spec.md`, AI-SOC should respond with:

**Status:** `202 Accepted`

**Body:**
```json
{
  "id": "threat_<uuid>",
  "threat_type": "device_compromise",
  "customer_name": "SeniorFraudShield",
  "timestamp": "<ISO-8601>",
  "metadata": {
    "external_alert_id": "1774207849.1724820513",
    "rule_id": "100006",
    "wazuh_rule_level": 15,
    "initial_severity_hint": "CRITICAL",
    "alert_summary": "Malicious Android app installed: com.test.package",
    "rule_groups": ["android", "package", "installandroid_install"],
    "repeat_count": 1,
    "wazuh_agent_id": "000",
    "wazuh_agent_name": "wazuh.manager",
    "wazuh_manager_name": "wazuh.manager",
    "decoder_name": "android_decoder_03",
    "package_name": "com.test.package",
    "source_ip": "192.168.65.1",
    "wazuh_location": "192.168.65.1",
    "endpoint_name": "emulator-5554",
    "log_message": "emulator-5554: D/BackupManagerService( 1198): ..."
  }
}
```

---

## Troubleshooting

### Issue: Connection Refused

**Symptom:**
```
ConnectionError: HTTPConnectionPool(host='172.20.0.1', port=8080): ... Connection refused
```

**Solutions:**
1. Verify AI-SOC is running: `kubectl get pods -n soc-agent-demo`
2. Check port forwarding: `kubectl get svc -n soc-agent-demo`
3. Test from host: `curl http://localhost:8080/health`

### Issue: 404 Not Found

**Symptom:**
```
< HTTP/1.1 404 Not Found
< nginx
```

**Solutions:**
1. Verify `Host: localhost` header is being sent
2. Check nginx ingress configuration
3. Verify endpoint path: `/api/threats/ingest/wazuh`

### Issue: 422 Unprocessable Entity

**Symptom:**
```
< HTTP/1.1 422 Unprocessable Entity
{"detail": {"message": "..."}}
```

**This is actually GOOD!** It means:
- ✅ Network connectivity works
- ✅ AI-SOC received the request
- ❌ Payload validation failed (check the error message)

---

## Files

- `mobile_demo/ossec.conf` - Wazuh configuration with integration
- `mobile_demo/patch_shuffle_for_kind.sh` - Script to add Host header
- `mobile_demo/trigger_ai_soc_test.sh` - End-to-end test script
- `mobile_demo/SPEC_COMPLIANCE_REPORT.md` - Spec compliance documentation

---

## Summary

✅ **Network**: Wazuh → `172.20.0.1:8080` → Kind cluster  
✅ **Headers**: `Content-Type: application/json`, `Host: localhost`  
✅ **Payload**: Compliant with `Wazuh-Webhook-Payload-Spec.md`  
✅ **Response**: Expecting `202 Accepted` with ThreatSignal  

**Next:** Monitor AI-SOC logs to verify alerts are being received and processed!

