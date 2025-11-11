# OneRingInc Rebranding - Quick Reference

## Custom Logo Files Location
**Directory:** `/Users/bhagirathi/wazuh/custom-logos/`

### All Custom Files Created (10 files):
1. `logo-light.svg` - Main text logo for light theme (200x40px)
2. `logo-dark.svg` - Main text logo for dark theme (200x40px)
3. `icon-light.svg` - Ring icon for light theme (32x32px)
4. `icon-dark.svg` - Ring icon for dark theme (32x32px)
5. `onering_mark_light.svg` - "O" mark for light theme (32x32px)
6. `onering_mark_dark.svg` - "O" mark for dark theme (32x32px)
7. `onering_full_light.svg` - Full logo with icon, light (240x50px)
8. `onering_full_dark.svg` - Full logo with icon, dark (240x50px)
9. `spinner_light.svg` - Animated loading spinner, light (60x60px)
10. `spinner_dark.svg` - Animated loading spinner, dark (60x60px)

## Files Replaced in Container (30+ files)

### Plugin Theme Assets (4 files)
**Path:** `/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/`
- `light/logo.svg`
- `light/icon.svg`
- `dark/logo.svg`
- `dark/icon.svg`

### Core UI Logos (18 files)
**Path:** `/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/`
- `wazuh_mark_on_light.svg`
- `wazuh_mark.svg`
- `wazuh_center_mark_on_light.svg`
- `wazuh_on_light.svg`
- `wazuh_mark_on_dark.svg`
- `wazuh_center_mark_on_dark.svg`
- `wazuh_on_dark.svg`
- `wazuh_center_mark.svg`
- `wazuh_dashboards_on_light.svg`
- `wazuh_dashboards.svg`
- `wazuh.svg`
- `wazuh_dashboards_on_dark.svg`
- `icon_light.svg`
- `icon_dark.svg`
- `spinner_on_light.svg`
- `spinner_on_dark.svg`

### Main Assets (1 file)
**Path:** `/usr/share/wazuh-dashboard/src/core/server/core_app/assets/`
- `wazuh_logo.svg`

### Default Branding (2 files)
**Path:** `/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/`
- `opensearch_mark_default_mode.svg`
- `opensearch_mark_dark_mode.svg`

## Configuration Files Modified (1 file)
- `/Users/bhagirathi/wazuh/wazuh-docker/single-node/config/wazuh_dashboard/opensearch_dashboards.yml`
  - Added: `server.name: "OneRingInc Security Platform"`

## Dashboard Access
- **URL:** https://localhost:443
- **Username:** admin
- **Password:** SecretPassword

## Quick Commands

### List custom logos
```bash
ls -la /Users/bhagirathi/wazuh/custom-logos/
```

### Restart dashboard
```bash
docker restart single-node-wazuh.dashboard-1
```

### Check dashboard status
```bash
docker ps | grep wazuh.dashboard
docker logs single-node-wazuh.dashboard-1 --tail 20
```

### Restore original branding
```bash
cd /Users/bhagirathi/wazuh/wazuh-docker/single-node
docker compose up -d --force-recreate wazuh.dashboard
```

## Image Summary

| Image | Dimensions | Purpose | Themes |
|-------|-----------|---------|--------|
| Logo | 200x40 | Main text logo | Light & Dark |
| Icon | 32x32 | Small ring icon | Light & Dark |
| Mark | 32x32 | "O" corner logo | Light & Dark |
| Full Logo | 240x50 | Logo + icon combined | Light & Dark |
| Spinner | 60x60 | Animated loading | Light & Dark |

**Total:** 10 custom SVG files → Replaced 25+ container files

## Color Scheme
- **Light Theme:** #2c3e50 (dark blue-gray)
- **Dark Theme:** #ffffff (white)
- **Font:** -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif

## See Full Documentation
For complete details: `/Users/bhagirathi/wazuh/ONERING_REBRAND_DOCUMENTATION.md`
