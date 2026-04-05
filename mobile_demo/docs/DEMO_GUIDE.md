# Demo Guide: Wazuh → AI-SOC Integration

This guide explains how to set up and maintain the Wazuh to AI-SOC integration for demonstrations and production use.

---

## 🚀 Quick Start After Restart

If you've restarted your computer, Wazuh containers, or AI-SOC cluster, follow these steps:

### Step 1: Verify Systems Are Running

```bash
# Check Wazuh is running
docker ps | grep wazuh

# Check AI-SOC cluster is running
kubectl get pods -n soc-agent-demo
```

**Expected output:**
- Wazuh: `single-node-wazuh.manager-1` should be "Up"
- AI-SOC: All pods should show "Running" status

---

### Step 2: Apply the Shuffle Patch

**⚠️ CRITICAL:** This patch must be applied **every time** Wazuh restarts.

```bash
cd /path/to/onering_wazuh
./mobile_demo/apply_permanent_shuffle_patch.sh
```

**What this does:**
1. Adds `Host: localhost` header (required for Kind Nginx Ingress routing)
2. Increases timeout from 10s to 30s (prevents timeout errors)

**Expected output:**
```
✅ Shuffle Patch Applied Successfully!
Headers:
    headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}
Timeout:
    res = requests.post(url, data=msg, headers=headers, timeout=30)
```

---

### Step 3: Test the Connection

Send a test alert to verify the integration:

```bash
echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.demo.test flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514
```

**Verify it worked:**

```bash
# Check Wazuh received the alert
docker exec single-node-wazuh.manager-1 tail -2 /var/ossec/logs/alerts/alerts.json | jq -r 'select(.rule.id == "100006") | .data.package_name'

# Check it reached AI-SOC (should see HTTP 202)
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=3 | grep "172.20.0.5"
```

**Expected output:**
- Wazuh: `com.demo.test`
- Ingress: `"POST /api/threats/ingest/wazuh HTTP/1.1" 202`

---

## 🔍 Troubleshooting

### Issue: Patch Not Applied

**Symptoms:**
- No alerts reaching AI-SOC
- Ingress logs show no traffic from `172.20.0.5`

**Solution:**
```bash
# Check if patch is applied
docker exec single-node-wazuh.manager-1 grep "Host" /var/ossec/integrations/shuffle.py

# If missing, reapply
./mobile_demo/apply_permanent_shuffle_patch.sh
```

---

### Issue: Timeout Errors (HTTP 499)

**Symptoms:**
- Ingress logs show `HTTP/1.1" 499` status

**Cause:**
- Patch not applied (timeout still at 10s)
- AI-SOC taking longer than timeout to process

**Solution:**
```bash
# Verify timeout is 30s
docker exec single-node-wazuh.manager-1 grep "timeout=" /var/ossec/integrations/shuffle.py

# Should show: timeout=30
# If shows timeout=10, reapply patch
./mobile_demo/apply_permanent_shuffle_patch.sh
```

---

### Issue: Wrong Ingress Endpoint

**Symptoms:**
- Wazuh logs show "Connection refused"

**Solution:**
```bash
# Check Kind network gateway
docker network inspect kind | jq -r '.[] | .IPAM.Config[0].Gateway'

# Should be: 172.20.0.1
# This is hardcoded in ossec.conf as: http://172.20.0.1:8080/api/threats/ingest/wazuh
```

---

## 📋 Pre-Demo Checklist

Before starting a demo, verify:

- [ ] Wazuh containers running (`docker ps | grep wazuh`)
- [ ] AI-SOC cluster running (`kubectl get pods -n soc-agent-demo`)
- [ ] Shuffle patch applied (`./mobile_demo/apply_permanent_shuffle_patch.sh`)
- [ ] Connection tested (send test alert)
- [ ] AI-SOC UI accessible at `http://localhost:8080`

---

## 🎯 Demo Flow

### 1. Show the Integration Architecture

Explain the flow:
```
Android Device → Wazuh Manager → AI-SOC Platform
                      ↓
                 Local Dashboard
```

### 2. Generate a Test Alert

```bash
echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.malicious.app flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514
```

### 3. Show Wazuh Processing

```bash
# Show the alert in Wazuh
docker exec single-node-wazuh.manager-1 tail -1 /var/ossec/logs/alerts/alerts.json | jq .
```

### 4. Show AI-SOC Analysis

Open browser to `http://localhost:8080` and show the threat feed with the new alert.

---

## 🔄 Maintenance

### After Every Restart

Run this **every time** you restart:
- Your computer
- Docker daemon  
- Wazuh containers
- AI-SOC cluster

```bash
./mobile_demo/apply_permanent_shuffle_patch.sh
```

### Optional: Automate the Patch

See [`PERMANENT_PATCH_GUIDE.md`](PERMANENT_PATCH_GUIDE.md) for automation options:
- Startup script
- Cron job
- Docker healthcheck

---

## 📚 Related Documentation

- [`WAVE3_SPECIFICATION.md`](WAVE3_SPECIFICATION.md) - Complete integration specification
- [`PERMANENT_PATCH_GUIDE.md`](../PERMANENT_PATCH_GUIDE.md) - Detailed patch management guide
- [`CHECKPOINT_LIVE_INTEGRATION.md`](../CHECKPOINT_LIVE_INTEGRATION.md) - Recovery reference
- [`../../README.md`](../../README.md) - Main project README

---

## ⚡ Quick Reference Commands

```bash
# Apply patch
./mobile_demo/apply_permanent_shuffle_patch.sh

# Send test alert
echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.app flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

# Check Wazuh alerts
docker exec single-node-wazuh.manager-1 tail -5 /var/ossec/logs/alerts/alerts.json | jq -r 'select(.rule.id == "100006") | .data.package_name'

# Check integration forwarding
docker exec single-node-wazuh.manager-1 tail -5 /var/ossec/logs/integrations.log

# Check ingress routing
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=10 | grep "172.20.0.5"

# Check AI-SOC backend
kubectl logs -n soc-agent-demo -l app=soc-backend --tail=20 | grep "COMPLETE"
```
