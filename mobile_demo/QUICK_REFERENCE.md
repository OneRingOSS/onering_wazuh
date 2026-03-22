# Quick Reference - Wazuh → AI-SOC Integration

## 🎯 Current Status
**✅ WORKING** - Alerts successfully reaching AI-SOC cluster  
**Last Updated:** 2026-03-22

---

## 🔑 Key Configuration

### Endpoint
```
http://172.20.0.1:8080/api/threats/ingest/wazuh
```

### Required Header
```
Host: localhost
```

### Wazuh Container
```
single-node-wazuh.manager-1
```

---

## ⚡ Quick Commands

### Trigger Test Alert
```bash
echo "emulator-5554: D/BackupManagerService( 1198): Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.now flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514
```

### Check Wazuh Forwarded Alert
```bash
docker exec single-node-wazuh.manager-1 tail -3 /var/ossec/logs/integrations.log
```

### Check Ingress Received Alert
```bash
kubectl logs -n ingress-nginx ingress-nginx-controller-589b66c8-kzp4b --tail=10 | grep "172.20.0.5"
```

### Check AI-SOC Backend Logs
```bash
kubectl logs -n soc-agent-demo -l app=soc-backend --tail=20
```

### Verify Shuffle Patch
```bash
docker exec single-node-wazuh.manager-1 grep "headers =" /var/ossec/integrations/shuffle.py
# Should show: headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}
```

### Verify Integration Config
```bash
docker exec single-node-wazuh.manager-1 grep -A 6 "<integration>" /var/ossec/etc/ossec.conf
```

---

## 🔧 Restore Working State

### 1. Apply Configuration
```bash
cd /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh
cp mobile_demo/ossec.conf /Users/satheesh/Documents/projects/wazuh-docker/single-node/ossec.conf
```

### 2. Restart Wazuh
```bash
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
```

### 3. Apply Host Header Patch
```bash
cd /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh
./mobile_demo/patch_shuffle_for_kind.sh
```

---

## 📊 Expected Results

### Successful Flow
```
1. Alert triggered → Wazuh logs in /var/ossec/logs/alerts/alerts.json
2. Shuffle forwards → Entry in /var/ossec/logs/integrations.log
3. Ingress receives → Log entry with source IP 172.20.0.5
4. Backend processes → AI-SOC logs show threat processing
```

### Current Status (as of checkpoint)
- ✅ Steps 1-3 working perfectly
- ⚠️ Step 4 has datetime bug (AI-SOC side, not Wazuh)

---

## 📁 Important Files

### Configuration
- `mobile_demo/ossec.conf` - Wazuh integration config
- `mobile_demo/CHECKPOINT_LIVE_INTEGRATION.md` - Full checkpoint documentation

### Scripts
- `mobile_demo/patch_shuffle_for_kind.sh` - Apply Host header patch
- `mobile_demo/trigger_ai_soc_test.sh` - Automated testing

### Documentation
- `mobile_demo/SHUFFLE_PAYLOAD_FORMAT.md` - Payload format details
- `mobile_demo/LIVE_AI_SOC_INTEGRATION.md` - Integration guide

---

## 🚨 Troubleshooting

### Alert not forwarded?
```bash
# Check if alert was generated
docker exec single-node-wazuh.manager-1 tail -20 /var/ossec/logs/alerts/alerts.json | grep "100006"

# Check integration is enabled
docker exec single-node-wazuh.manager-1 grep -i "shuffle" /var/ossec/logs/ossec.log | tail -5
```

### Request not reaching ingress?
```bash
# Verify Host header is present
docker exec single-node-wazuh.manager-1 grep "headers =" /var/ossec/integrations/shuffle.py

# If missing, re-apply patch
./mobile_demo/patch_shuffle_for_kind.sh
```

### Getting HTTP 422?
```bash
# AI-SOC doesn't support Shuffle format
# Check AI-SOC agent has all_fields extraction code
```

### Getting HTTP 500?
```bash
# Known datetime bug in AI-SOC timeline builder
# Not a Wazuh issue - wait for AI-SOC team fix
```

---

## 🎯 Success Criteria

✅ **Working:**
- Wazuh detects package installations
- Shuffle forwards to `172.20.0.1:8080`
- Ingress shows `172.20.0.5` POST requests
- AI-SOC starts processing (response plan generated)

⏳ **Pending:**
- AI-SOC datetime bug fix
- HTTP 202 response instead of 500
- Threat appears in AI-SOC dashboard

---

**For detailed information, see `CHECKPOINT_LIVE_INTEGRATION.md`**

