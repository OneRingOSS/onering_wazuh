# OneRingInc Wazuh Dashboard Rebranding Documentation

**Date:** November 8, 2025
**Original Platform:** Wazuh 4.13.0 Dashboard
**Rebranded To:** OneRingInc Security Platform
**Installation Path:** `/Users/bhagirathi/wazuh/wazuh-docker/single-node`

---

## Table of Contents
1. [Overview](#overview)
2. [Custom Logo Files Created](#custom-logo-files-created)
3. [Files Modified in Dashboard Container](#files-modified-in-dashboard-container)
4. [Configuration Changes](#configuration-changes)
5. [Step-by-Step Replication Guide](#step-by-step-replication-guide)
6. [How to Restore Original Branding](#how-to-restore-original-branding)
7. [Testing and Verification](#testing-and-verification)

---

## Overview

This document details the complete rebranding of a Wazuh dashboard installation to remove all "Wazuh" branding and replace it with "OneRingInc" branding for presentation purposes.

### What Was Changed:
- ✅ Login page logo
- ✅ Loading screen spinner
- ✅ Corner logo (top-left "W" mark)
- ✅ Sidebar logos
- ✅ Header logos
- ✅ All icon variants (light/dark themes)
- ✅ Dashboard title configuration

### What Was NOT Changed:
- ⚠️ Text references in menu items (hardcoded in plugin)
- ⚠️ Documentation links
- ⚠️ Some internal configuration pages

---

## Custom Logo Files Created

All custom logo files are located in: `/Users/bhagirathi/wazuh/custom-logos/`

### 1. **Logo Files (Light Theme)**
**File:** `logo-light.svg`
**Dimensions:** 200x40 pixels
**Description:** Text-based logo displaying "OneRingInc" in dark color (#2c3e50)
**Used For:** Main logo in light theme

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="200" height="40" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .logo-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 28px;
        font-weight: 600;
        fill: #2c3e50;
      }
    </style>
  </defs>
  <text x="10" y="30" class="logo-text">OneRingInc</text>
</svg>
```

---

### 2. **Logo Files (Dark Theme)**
**File:** `logo-dark.svg`
**Dimensions:** 200x40 pixels
**Description:** Text-based logo displaying "OneRingInc" in white
**Used For:** Main logo in dark theme

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="200" height="40" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .logo-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 28px;
        font-weight: 600;
        fill: #ffffff;
      }
    </style>
  </defs>
  <text x="10" y="30" class="logo-text">OneRingInc</text>
</svg>
```

---

### 3. **Icon Files (Light Theme)**
**File:** `icon-light.svg`
**Dimensions:** 32x32 pixels
**Description:** Two concentric rings representing "OneRing"
**Used For:** Small icon/favicon in light theme

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <circle cx="16" cy="16" r="14" fill="none" stroke="#2c3e50" stroke-width="3"/>
  <circle cx="16" cy="16" r="8" fill="none" stroke="#2c3e50" stroke-width="2"/>
</svg>
```

---

### 4. **Icon Files (Dark Theme)**
**File:** `icon-dark.svg`
**Dimensions:** 32x32 pixels
**Description:** Two concentric rings in white
**Used For:** Small icon/favicon in dark theme

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <circle cx="16" cy="16" r="14" fill="none" stroke="#ffffff" stroke-width="3"/>
  <circle cx="16" cy="16" r="8" fill="none" stroke="#ffffff" stroke-width="2"/>
</svg>
```

---

### 5. **Mark/Corner Logo (Light Theme)**
**File:** `onering_mark_light.svg`
**Dimensions:** 32x32 pixels
**Description:** Letter "O" in a circle for corner logo
**Used For:** Top-left corner mark, login page mark

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .ring-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 24px;
        font-weight: 700;
        fill: #2c3e50;
      }
    </style>
  </defs>
  <circle cx="16" cy="16" r="14" fill="none" stroke="#2c3e50" stroke-width="2.5"/>
  <text x="16" y="22" class="ring-text" text-anchor="middle">O</text>
</svg>
```

---

### 6. **Mark/Corner Logo (Dark Theme)**
**File:** `onering_mark_dark.svg`
**Dimensions:** 32x32 pixels
**Description:** Letter "O" in a circle (white) for dark theme
**Used For:** Top-left corner mark in dark mode

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .ring-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 24px;
        font-weight: 700;
        fill: #ffffff;
      }
    </style>
  </defs>
  <circle cx="16" cy="16" r="14" fill="none" stroke="#ffffff" stroke-width="2.5"/>
  <text x="16" y="22" class="ring-text" text-anchor="middle">O</text>
</svg>
```

---

### 7. **Full Logo with Icon (Light Theme)**
**File:** `onering_full_light.svg`
**Dimensions:** 240x50 pixels
**Description:** Circle icon + "OneRingInc" text combined
**Used For:** Login page, dashboard headers

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="240" height="50" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .logo-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 32px;
        font-weight: 600;
        fill: #2c3e50;
      }
    </style>
  </defs>
  <circle cx="25" cy="25" r="20" fill="none" stroke="#2c3e50" stroke-width="3"/>
  <text x="55" y="35" class="logo-text">OneRingInc</text>
</svg>
```

---

### 8. **Full Logo with Icon (Dark Theme)**
**File:** `onering_full_dark.svg`
**Dimensions:** 240x50 pixels
**Description:** Circle icon + "OneRingInc" text (white)
**Used For:** Login page, dashboard headers (dark mode)

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="240" height="50" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .logo-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 32px;
        font-weight: 600;
        fill: #ffffff;
      }
    </style>
  </defs>
  <circle cx="25" cy="25" r="20" fill="none" stroke="#ffffff" stroke-width="3"/>
  <text x="55" y="35" class="logo-text">OneRingInc</text>
</svg>
```

---

### 9. **Loading Spinner (Light Theme)**
**File:** `spinner_light.svg`
**Dimensions:** 60x60 pixels
**Description:** Animated spinning ring with "O" in center
**Used For:** Loading screens, page transitions

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="60" height="60" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .spinner-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 14px;
        font-weight: 600;
        fill: #2c3e50;
      }
    </style>
  </defs>
  <circle cx="30" cy="30" r="25" fill="none" stroke="#2c3e50" stroke-width="3" opacity="0.3"/>
  <circle cx="30" cy="30" r="25" fill="none" stroke="#2c3e50" stroke-width="3"
          stroke-dasharray="40 120" stroke-linecap="round">
    <animateTransform attributeName="transform" type="rotate" from="0 30 30" to="360 30 30"
                      dur="1s" repeatCount="indefinite"/>
  </circle>
  <text x="30" y="35" class="spinner-text" text-anchor="middle">O</text>
</svg>
```

---

### 10. **Loading Spinner (Dark Theme)**
**File:** `spinner_dark.svg`
**Dimensions:** 60x60 pixels
**Description:** Animated spinning ring with "O" (white)
**Used For:** Loading screens in dark mode

```svg
<?xml version="1.0" encoding="UTF-8"?>
<svg width="60" height="60" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .spinner-text {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
        font-size: 14px;
        font-weight: 600;
        fill: #ffffff;
      }
    </style>
  </defs>
  <circle cx="30" cy="30" r="25" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.3"/>
  <circle cx="30" cy="30" r="25" fill="none" stroke="#ffffff" stroke-width="3"
          stroke-dasharray="40 120" stroke-linecap="round">
    <animateTransform attributeName="transform" type="rotate" from="0 30 30" to="360 30 30"
                      dur="1s" repeatCount="indefinite"/>
  </circle>
  <text x="30" y="35" class="spinner-text" text-anchor="middle">O</text>
</svg>
```

---

## Files Modified in Dashboard Container

All modifications were made inside the Docker container: `single-node-wazuh.dashboard-1`

### **Plugin Theme Assets**
**Container Path:** `/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/`

| Original File | Replaced With | Description |
|--------------|---------------|-------------|
| `light/logo.svg` | `logo-light.svg` | Main logo (light theme) |
| `light/icon.svg` | `icon-light.svg` | Icon (light theme) |
| `dark/logo.svg` | `logo-dark.svg` | Main logo (dark theme) |
| `dark/icon.svg` | `icon-dark.svg` | Icon (dark theme) |

**Commands Used:**
```bash
docker cp /Users/bhagirathi/wazuh/custom-logos/logo-light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/light/logo.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/icon-light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/light/icon.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/logo-dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/dark/logo.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/icon-dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/dark/icon.svg
```

---

### **Core UI Logos**
**Container Path:** `/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/`

| Original File | Replaced With | Used For |
|--------------|---------------|----------|
| `wazuh_mark_on_light.svg` | `onering_mark_light.svg` | Corner mark (light) |
| `wazuh_mark.svg` | `onering_mark_light.svg` | Generic mark |
| `wazuh_center_mark_on_light.svg` | `onering_mark_light.svg` | Center mark (light) |
| `wazuh_on_light.svg` | `onering_mark_light.svg` | UI element (light) |
| `wazuh_mark_on_dark.svg` | `onering_mark_dark.svg` | Corner mark (dark) |
| `wazuh_center_mark_on_dark.svg` | `onering_mark_dark.svg` | Center mark (dark) |
| `wazuh_on_dark.svg` | `onering_mark_dark.svg` | UI element (dark) |
| `wazuh_center_mark.svg` | `onering_mark_dark.svg` | Generic center mark |
| `wazuh_dashboards_on_light.svg` | `onering_full_light.svg` | Full logo (light) |
| `wazuh_dashboards.svg` | `onering_full_light.svg` | Dashboard logo |
| `wazuh.svg` | `onering_full_light.svg` | Generic full logo |
| `wazuh_dashboards_on_dark.svg` | `onering_full_dark.svg` | Full logo (dark) |
| `icon_light.svg` | `icon-light.svg` | Icon (light) |
| `icon_dark.svg` | `icon-dark.svg` | Icon (dark) |
| `spinner_on_light.svg` | `spinner_light.svg` | Loading spinner (light) |
| `spinner_on_dark.svg` | `spinner_dark.svg` | Loading spinner (dark) |

**Commands Used:**
```bash
# Light theme marks
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark_on_light.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark_on_light.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_on_light.svg

# Dark theme marks
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark_on_dark.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark_on_dark.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_on_dark.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark.svg

# Full logos
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards_on_light.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_full_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards_on_dark.svg

# Icons
docker cp /Users/bhagirathi/wazuh/custom-logos/icon-light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/icon_light.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/icon-dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/icon_dark.svg

# Spinners
docker cp /Users/bhagirathi/wazuh/custom-logos/spinner_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/spinner_on_light.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/spinner_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/spinner_on_dark.svg
```

---

### **Main Assets Directory**
**Container Path:** `/usr/share/wazuh-dashboard/src/core/server/core_app/assets/`

| Original File | Replaced With | Used For |
|--------------|---------------|----------|
| `wazuh_logo.svg` | `onering_full_light.svg` | Main dashboard logo |

**Command Used:**
```bash
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/wazuh_logo.svg
```

---

### **Default Branding**
**Container Path:** `/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/`

| Original File | Replaced With | Used For |
|--------------|---------------|----------|
| `opensearch_mark_default_mode.svg` | `onering_mark_light.svg` | Fallback logo (light) |
| `opensearch_mark_dark_mode.svg` | `onering_mark_dark.svg` | Fallback logo (dark) |

**Commands Used:**
```bash
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/opensearch_mark_default_mode.svg
docker cp /Users/bhagirathi/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/opensearch_mark_dark_mode.svg
```

---

## Configuration Changes

### **1. OpenSearch Dashboards Configuration**
**Host Path:** `/Users/bhagirathi/wazuh/wazuh-docker/single-node/config/wazuh_dashboard/opensearch_dashboards.yml`

**Changes Made:**
- Added `server.name: "OneRingInc Security Platform"` to customize server name

**Modified Configuration:**
```yaml
server.host: 0.0.0.0
server.port: 5601
server.name: "OneRingInc Security Platform"  # <-- ADDED THIS LINE
opensearch.hosts: https://wazuh.indexer:9200
opensearch.ssl.verificationMode: certificate
opensearch.requestHeadersWhitelist: ["securitytenant","Authorization"]
opensearch_security.multitenancy.enabled: false
opensearch_security.readonly_mode.roles: ["kibana_read_only"]
server.ssl.enabled: true
server.ssl.key: "/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem"
server.ssl.certificate: "/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem"
opensearch.ssl.certificateAuthorities: ["/usr/share/wazuh-dashboard/certs/root-ca.pem"]
uiSettings.overrides.defaultRoute: /app/wz-home
# Session expiration settings
opensearch_security.cookie.ttl: 900000
opensearch_security.session.ttl: 900000
opensearch_security.session.keepalive: true
```

---

### **2. Wazuh Dashboard Configuration**
**Host Path:** `/Users/bhagirathi/wazuh/wazuh-docker/single-node/config/wazuh_dashboard/wazuh.yml`

**Changes Made:**
- No functional changes (kept original configuration)
- Initial attempts to add customization settings were reverted as they caused errors

**Final Configuration (unchanged):**
```yaml
hosts:
  - 1513629884013:
      url: "https://wazuh.manager"
      port: 55000
      username: wazuh-wui
      password: "MyS3cr37P450r.*-"
      run_as: false
```

---

## Step-by-Step Replication Guide

If you need to replicate this rebranding on another Wazuh installation:

### Prerequisites
```bash
# Ensure Docker is running
docker --version
docker compose version

# Ensure you have a running Wazuh dashboard container
docker ps | grep wazuh.dashboard
```

### Step 1: Create Custom Logo Files
```bash
# Create directory for custom logos
mkdir -p ~/wazuh/custom-logos
cd ~/wazuh/custom-logos

# Create all 10 logo files (use SVG code from "Custom Logo Files Created" section above)
# Files to create:
# - logo-light.svg
# - logo-dark.svg
# - icon-light.svg
# - icon-dark.svg
# - onering_mark_light.svg
# - onering_mark_dark.svg
# - onering_full_light.svg
# - onering_full_dark.svg
# - spinner_light.svg
# - spinner_dark.svg
```

### Step 2: Copy Plugin Theme Logos
```bash
docker cp ~/wazuh/custom-logos/logo-light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/light/logo.svg
docker cp ~/wazuh/custom-logos/icon-light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/light/icon.svg
docker cp ~/wazuh/custom-logos/logo-dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/dark/logo.svg
docker cp ~/wazuh/custom-logos/icon-dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/dark/icon.svg
```

### Step 3: Replace Core UI Logos
```bash
# Light theme marks
docker cp ~/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark_on_light.svg
docker cp ~/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark.svg
docker cp ~/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark_on_light.svg
docker cp ~/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_on_light.svg

# Dark theme marks
docker cp ~/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark_on_dark.svg
docker cp ~/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark_on_dark.svg
docker cp ~/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_on_dark.svg
docker cp ~/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark.svg

# Full logos
docker cp ~/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards_on_light.svg
docker cp ~/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards.svg
docker cp ~/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh.svg
docker cp ~/wazuh/custom-logos/onering_full_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards_on_dark.svg

# Icons
docker cp ~/wazuh/custom-logos/icon-light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/icon_light.svg
docker cp ~/wazuh/custom-logos/icon-dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/icon_dark.svg

# Spinners
docker cp ~/wazuh/custom-logos/spinner_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/spinner_on_light.svg
docker cp ~/wazuh/custom-logos/spinner_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/spinner_on_dark.svg
```

### Step 4: Replace Main Logo and Default Branding
```bash
# Main logo
docker cp ~/wazuh/custom-logos/onering_full_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/wazuh_logo.svg

# Default branding
docker cp ~/wazuh/custom-logos/onering_mark_light.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/opensearch_mark_default_mode.svg
docker cp ~/wazuh/custom-logos/onering_mark_dark.svg single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/opensearch_mark_dark_mode.svg
```

### Step 5: Update Configuration
```bash
# Edit opensearch_dashboards.yml
# Add this line after server.port:
# server.name: "OneRingInc Security Platform"

# Path: ~/wazuh/wazuh-docker/single-node/config/wazuh_dashboard/opensearch_dashboards.yml
```

### Step 6: Restart Dashboard
```bash
docker restart single-node-wazuh.dashboard-1

# Wait for restart (30-40 seconds)
sleep 35

# Verify it's running
docker ps | grep wazuh.dashboard
docker logs single-node-wazuh.dashboard-1 --tail 10
```

### Step 7: Verify Changes
```bash
# Open browser to https://localhost:443
# Username: admin
# Password: SecretPassword

# Check:
# - Login page logo shows OneRingInc
# - Loading spinner shows "O" ring
# - Corner logo shows "O" instead of "W"
# - All UI elements show OneRingInc branding
```

---

## How to Restore Original Branding

### Option 1: Rebuild Dashboard Container (Recommended)
```bash
cd ~/wazuh/wazuh-docker/single-node

# Stop and remove dashboard container
docker stop single-node-wazuh.dashboard-1
docker rm single-node-wazuh.dashboard-1

# Recreate dashboard with original image
docker compose up -d wazuh.dashboard

# This will pull fresh container with original Wazuh branding
```

### Option 2: Manual Restoration (if you have backups)
If you created backups before making changes:

```bash
# Restore from backup (example)
docker cp ~/wazuh/backup/original-logos/ single-node-wazuh.dashboard-1:/usr/share/wazuh-dashboard/

# Restart dashboard
docker restart single-node-wazuh.dashboard-1
```

### Option 3: Remove Configuration Changes
```bash
# Edit opensearch_dashboards.yml
# Remove line: server.name: "OneRingInc Security Platform"

# Restart dashboard
docker restart single-node-wazuh.dashboard-1
```

---

## Testing and Verification

### Verification Checklist
After completing the rebranding, verify the following:

- [ ] **Login Page**
  - [ ] Logo shows "OneRingInc" (not Wazuh)
  - [ ] No "Wazuh" text visible on login screen

- [ ] **Loading Screen**
  - [ ] Spinner shows animated "O" ring (not Wazuh logo)

- [ ] **Dashboard UI**
  - [ ] Top-left corner shows "O" mark (not "W")
  - [ ] Sidebar logo is OneRingInc
  - [ ] Header shows OneRingInc branding

- [ ] **Theme Switching**
  - [ ] Light theme: Dark logos visible
  - [ ] Dark theme: White logos visible
  - [ ] All logos change appropriately with theme

- [ ] **Browser Tab**
  - [ ] Page title shows "OneRingInc Security Platform" (if configured)
  - [ ] Favicon shows ring icon

- [ ] **Page Navigation**
  - [ ] All pages maintain OneRingInc branding
  - [ ] No Wazuh logos appear during navigation

- [ ] **Data Loading**
  - [ ] Loading spinners show OneRingInc "O" animation
  - [ ] No Wazuh branding during data loads

### Known Limitations

**Text References Still Showing "Wazuh":**
- Menu item names (e.g., "Wazuh" module names)
- Documentation links
- Some configuration pages
- Error messages
- API endpoint names

**Why These Weren't Changed:**
These are hardcoded in the Wazuh plugin JavaScript/TypeScript source code. Changing them would require:
1. Accessing the plugin source code
2. Modifying and recompiling JavaScript bundles
3. Potentially breaking functionality
4. More complex maintenance

**For Presentation Purposes:**
The visual branding (logos, icons, spinners) changes are sufficient for most presentations. The remaining text references are typically in administrative areas that may not be shown.

---

## Summary of All Files

### Custom Logo Files (10 files)
```
/Users/bhagirathi/wazuh/custom-logos/
├── logo-light.svg               # Main logo (light theme)
├── logo-dark.svg                # Main logo (dark theme)
├── icon-light.svg               # Icon (light theme)
├── icon-dark.svg                # Icon (dark theme)
├── onering_mark_light.svg       # Corner mark (light theme)
├── onering_mark_dark.svg        # Corner mark (dark theme)
├── onering_full_light.svg       # Full logo with icon (light)
├── onering_full_dark.svg        # Full logo with icon (dark)
├── spinner_light.svg            # Loading spinner (light)
└── spinner_dark.svg             # Loading spinner (dark)
```

### Container Files Modified (30+ files)
```
/usr/share/wazuh-dashboard/
├── plugins/wazuh/public/assets/images/themes/
│   ├── light/
│   │   ├── logo.svg             # REPLACED
│   │   └── icon.svg             # REPLACED
│   └── dark/
│       ├── logo.svg             # REPLACED
│       └── icon.svg             # REPLACED
├── src/core/server/core_app/assets/
│   ├── wazuh_logo.svg           # REPLACED
│   ├── logos/
│   │   ├── wazuh_mark_on_light.svg        # REPLACED
│   │   ├── wazuh_mark.svg                 # REPLACED
│   │   ├── wazuh_center_mark_on_light.svg # REPLACED
│   │   ├── wazuh_on_light.svg             # REPLACED
│   │   ├── wazuh_mark_on_dark.svg         # REPLACED
│   │   ├── wazuh_center_mark_on_dark.svg  # REPLACED
│   │   ├── wazuh_on_dark.svg              # REPLACED
│   │   ├── wazuh_center_mark.svg          # REPLACED
│   │   ├── wazuh_dashboards_on_light.svg  # REPLACED
│   │   ├── wazuh_dashboards.svg           # REPLACED
│   │   ├── wazuh.svg                      # REPLACED
│   │   ├── wazuh_dashboards_on_dark.svg   # REPLACED
│   │   ├── icon_light.svg                 # REPLACED
│   │   ├── icon_dark.svg                  # REPLACED
│   │   ├── spinner_on_light.svg           # REPLACED
│   │   └── spinner_on_dark.svg            # REPLACED
│   └── default_branding/
│       ├── opensearch_mark_default_mode.svg # REPLACED
│       └── opensearch_mark_dark_mode.svg    # REPLACED
```

### Configuration Files Modified (1 file)
```
/Users/bhagirathi/wazuh/wazuh-docker/single-node/config/wazuh_dashboard/
└── opensearch_dashboards.yml    # MODIFIED (added server.name)
```

---

## Contact & Support

**Installation Date:** November 8, 2025
**Wazuh Version:** 4.13.0
**Dashboard URL:** https://localhost:443
**Default Credentials:** admin / SecretPassword

**Important Notes:**
- All changes are container-level modifications
- Changes will persist until container is recreated from original image
- To permanently apply changes, consider building a custom Docker image
- This rebranding is for presentation/demo purposes

---

**End of Documentation**
