# Shuffle Patch Guide for Kind Cluster Integration

## Overview

This guide explains how to apply and maintain the Wazuh Shuffle integration patch required for the AI-SOC Kind cluster integration.

## Problem

The Wazuh Shuffle integration needs to send a `Host: localhost` header with all webhook requests to the AI-SOC Kind cluster. Without this header, the Kind Nginx Ingress cannot properly route the traffic to the backend service.

**⚠️ Important:** Due to how Wazuh initializes its integration files, the patch needs to be reapplied after container restarts.

**Before the patch:**
```python
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}
```

**After the patch:**
```python
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}
```

## Why the Patch is Needed

The AI-SOC backend runs in a Kind (Kubernetes in Docker) cluster with Nginx Ingress. The ingress is configured to route traffic based on the `Host` header:

```yaml
Host: localhost
  /api       → soc-agent-backend:8000
  /ws        → soc-agent-backend:8000
  /metrics   → soc-agent-backend:8000
```

When Wazuh sends requests from the Docker network to the Kind cluster at `http://172.20.0.1:8080/api/threats/ingest/wazuh`, the Nginx Ingress needs the `Host: localhost` header to know which service to route to.

## Solution: Post-Restart Patch Application

The `/var/ossec/integrations` directory in the Wazuh container is mounted as a Docker volume, but Wazuh reinitializes integration files on startup. Therefore, the patch must be reapplied after each container restart.

We provide an automated script that makes this process simple and reliable.

## How to Apply the Patch

### Automatic Method (Recommended)

Run the automated script after starting or restarting the Wazuh container:

```bash
./mobile_demo/apply_permanent_shuffle_patch.sh
```

This script will:
1. Extract the current `shuffle.py` from the container
2. Apply the Host header patch
3. Copy the patched file back to the container
4. Set correct permissions (750, root:wazuh)
5. Save a backup copy to the wazuh-docker directory
6. Verify the patch was applied

**When to run this script:**
- After initial Wazuh setup
- After restarting the Wazuh container
- After AI-SOC cluster restarts (if you notice integration failures)

### Manual Method

If you need to apply the patch manually:

```bash
# 1. Extract current shuffle.py
docker exec single-node-wazuh.manager-1 cat /var/ossec/integrations/shuffle.py > /tmp/shuffle.py

# 2. Edit the file to add 'Host': 'localhost' to the headers dict

# 3. Copy back to container
docker cp /tmp/shuffle.py single-node-wazuh.manager-1:/var/ossec/integrations/shuffle.py

# 4. Fix permissions
docker exec single-node-wazuh.manager-1 chmod 750 /var/ossec/integrations/shuffle.py
docker exec single-node-wazuh.manager-1 chown root:wazuh /var/ossec/integrations/shuffle.py
```

## Verification

### 1. Check the Patch is Applied

```bash
docker exec single-node-wazuh.manager-1 grep "headers = " /var/ossec/integrations/shuffle.py
```

Expected output:
```python
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8', 'Host': 'localhost'}
```

### 2. Test with a Real Alert

```bash
./mobile_demo/trigger_ai_soc_test.sh
```

Check the ingress logs for HTTP 202:
```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=5 | grep "172.20.0.5"
```

Expected output:
```
172.20.0.5 - - [...] "POST /api/threats/ingest/wazuh HTTP/1.1" 202 ...
```

### 3. After Container Restart

```bash
# Restart the Wazuh container
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager

# Wait for container to start (5-10 seconds)
sleep 10

# Reapply the patch
cd /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh
./mobile_demo/apply_permanent_shuffle_patch.sh

# Verify patch is applied
docker exec single-node-wazuh.manager-1 grep "headers = " /var/ossec/integrations/shuffle.py
```

## Automation Options

### Option 1: Manual Reapplication (Current Approach)

After each Wazuh container restart, manually run:
```bash
./mobile_demo/apply_permanent_shuffle_patch.sh
```

### Option 2: Add to Startup Script

Create a startup script that restarts Wazuh and applies the patch:

```bash
#!/bin/bash
# restart_wazuh_with_patch.sh
cd /Users/satheesh/Documents/projects/wazuh-docker/single-node
docker-compose restart wazuh.manager
sleep 10
cd /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh
./mobile_demo/apply_permanent_shuffle_patch.sh
```

### Option 3: Cron Job (Advanced)

Create a cron job that checks and reapplies the patch if needed:

```bash
# Add to crontab (crontab -e)
*/5 * * * * /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh/mobile_demo/check_and_patch.sh
```

Then create `check_and_patch.sh`:
```bash
#!/bin/bash
# Check if patch is applied, if not, apply it
CURRENT=$(docker exec single-node-wazuh.manager-1 grep "headers = " /var/ossec/integrations/shuffle.py 2>/dev/null)
if [[ ! "$CURRENT" =~ "Host.*localhost" ]]; then
    /Users/satheesh/Documents/projects/onering-wazuh/onering-dash/onering_wazuh/mobile_demo/apply_permanent_shuffle_patch.sh
fi
```

## Troubleshooting

### Patch Lost After Restart

This is expected behavior. Wazuh reinitializes integration files on startup. Simply reapply:

```bash
./mobile_demo/apply_permanent_shuffle_patch.sh
```

### HTTP 404 or 405 Errors

If you see HTTP 404 or 405 errors in the ingress logs, the Host header is missing. Verify:

```bash
docker exec single-node-wazuh.manager-1 grep "Host" /var/ossec/integrations/shuffle.py
```

### Integration Not Working

Check the full integration flow:

```bash
# 1. Check Wazuh integration logs
docker exec single-node-wazuh.manager-1 tail -5 /var/ossec/logs/integrations.log

# 2. Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=10

# 3. Check AI-SOC backend logs
kubectl logs -n soc-agent-demo -l app=soc-backend --tail=20
```

## Files

- **Patch Script:** `mobile_demo/apply_permanent_shuffle_patch.sh`
- **Backup Location:** `/Users/satheesh/Documents/projects/wazuh-docker/single-node/shuffle.py`
- **Container Location:** `/var/ossec/integrations/shuffle.py` (in Docker volume)

## Summary

✅ **Automated patch script available** - quick and reliable reapplication
✅ **Backup saved** - patched file stored in wazuh-docker directory for reference
✅ **Verified working** - tested end-to-end with real alerts
✅ **Multiple automation options** - choose what works best for your workflow

**Important Notes:**
- The patch must be reapplied after Wazuh container restarts
- The automated script makes this process simple (< 10 seconds)
- Consider adding the patch script to your startup routine
- The integration works perfectly once the patch is applied

**Quick Reference:**
```bash
# After any Wazuh restart, run:
./mobile_demo/apply_permanent_shuffle_patch.sh

# Then verify:
./mobile_demo/trigger_ai_soc_test.sh
```

