# OneRingInc Wazuh Dashboard Rebranding Package

Hey! This package contains everything you need to rebrand a Wazuh dashboard with OneRingInc branding.

## What's Included

```
📦 OneRingInc_Wazuh_Rebrand/
├── 📁 custom-logos/              # All 10 custom logo files
├── 📄 rebrand_wazuh.sh           # Automated rebranding script
├── 📄 ONERING_REBRAND_DOCUMENTATION.md  # Complete documentation
├── 📄 QUICK_REFERENCE.md         # Quick reference guide
├── 📄 REBRAND_SUMMARY.txt        # Summary overview
├── 📄 README_FOR_FRIEND.md       # This file
└── 🐳 wazuh-dashboard-onering.tar (optional) # Pre-rebranded Docker image
```

---

## 🚀 Quick Start (3 Options)

### **Option 1: Use Pre-Built Docker Image** (Easiest - 2 minutes)

If you received the Docker image file:

```bash
# 1. Load the image
docker load -i wazuh-dashboard-onering.tar

# 2. Tag it properly
docker tag wazuh-dashboard-onering:latest wazuh/wazuh-dashboard:4.13.0

# 3. Start your Wazuh stack
cd your-wazuh-installation
docker compose up -d

# Done! Access at https://localhost:443
# Username: admin
# Password: SecretPassword
```

---

### **Option 2: Run Automated Script** (Easy - 5 minutes)

If you already have Wazuh running:

```bash
# 1. Extract this package
unzip OneRingInc_Wazuh_Rebrand.zip
cd OneRingInc_Wazuh_Rebrand

# 2. Run the script
./rebrand_wazuh.sh

# Or specify your container name:
./rebrand_wazuh.sh my-wazuh-dashboard-container

# Done! The script does everything automatically
```

**What the script does:**
- ✓ Checks prerequisites
- ✓ Replaces all 25+ logo files
- ✓ Restarts dashboard
- ✓ Verifies installation
- ✓ Shows summary

---

### **Option 3: Manual Installation** (Advanced - 15 minutes)

Follow the step-by-step guide in `ONERING_REBRAND_DOCUMENTATION.md`

---

## 📋 Requirements

Before you start, make sure you have:

- ✅ Docker installed and running
- ✅ Wazuh dashboard container running (version 4.13.0 recommended)
- ✅ Basic terminal/command line knowledge
- ✅ 5-10 minutes of time

**To check if Wazuh is running:**
```bash
docker ps | grep wazuh
```

You should see containers for:
- wazuh.manager
- wazuh.indexer
- wazuh.dashboard

---

## 🎯 What Gets Rebranded

After applying this package, your Wazuh dashboard will have:

✅ **OneRingInc** logo on login page (instead of Wazuh)
✅ **"O" ring icon** in the corner (instead of "W")
✅ **OneRingInc** branding in sidebar and header
✅ **Animated "O" spinner** on loading screens
✅ **All logos** updated for both light and dark themes

⚠️ **What stays the same:**
- Menu text labels (these are hardcoded in the plugin)
- Dashboard functionality (100% same features)
- Your data and configurations

---

## 📖 Detailed Guides

### 1. **Complete Documentation**
`ONERING_REBRAND_DOCUMENTATION.md` - Everything you need to know:
- All logo SVG code
- Step-by-step manual instructions
- Configuration details
- Troubleshooting
- How to restore original branding

### 2. **Quick Reference**
`QUICK_REFERENCE.md` - Fast lookup:
- File locations
- Common commands
- Quick troubleshooting

### 3. **Summary**
`REBRAND_SUMMARY.txt` - Overview:
- What changed
- File list
- Checklist

---

## 🛠️ Troubleshooting

### Dashboard won't start after rebranding

```bash
# Check logs
docker logs your-dashboard-container --tail 50

# Common fix: Restart the container
docker restart your-dashboard-container

# Wait 30 seconds
sleep 30

# Try accessing again
# https://localhost:443
```

### Logos not showing

```bash
# Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)
# Or open in incognito/private window
```

### Container name not found

```bash
# List all containers
docker ps -a

# Use the exact name:
./rebrand_wazuh.sh exact-container-name
```

### Script permission denied

```bash
# Make script executable
chmod +x rebrand_wazuh.sh

# Then run it
./rebrand_wazuh.sh
```

---

## 🔄 How to Restore Original Wazuh Branding

If you want to go back to Wazuh branding:

### Quick Method:
```bash
cd your-wazuh-installation
docker compose up -d --force-recreate wazuh.dashboard
```

This recreates the container from the original image.

### Or rebuild from scratch:
```bash
docker stop wazuh.dashboard
docker rm wazuh.dashboard
docker compose up -d
```

---

## 📸 Screenshots / Verification

After rebranding, you should see:

**Login Page:**
- OneRingInc logo (not Wazuh)

**Dashboard Corner (top-left):**
- "O" in a circle (not "W")

**Loading Screens:**
- Animated spinning "O" ring

**Sidebar:**
- OneRingInc branding

**Light/Dark Themes:**
- Logos automatically switch colors

---

## 🎨 Logo Details

This package includes 10 custom-designed SVG logos:

| File | Size | Purpose |
|------|------|---------|
| `logo-light.svg` | 200x40 | Main text logo (light theme) |
| `logo-dark.svg` | 200x40 | Main text logo (dark theme) |
| `icon-light.svg` | 32x32 | Ring icon (light theme) |
| `icon-dark.svg` | 32x32 | Ring icon (dark theme) |
| `onering_mark_light.svg` | 32x32 | "O" mark (light theme) |
| `onering_mark_dark.svg` | 32x32 | "O" mark (dark theme) |
| `onering_full_light.svg` | 240x50 | Full logo + icon (light) |
| `onering_full_dark.svg` | 240x50 | Full logo + icon (dark) |
| `spinner_light.svg` | 60x60 | Loading spinner (light) |
| `spinner_dark.svg` | 60x60 | Loading spinner (dark) |

**Design:**
- Brand: OneRingInc
- Icon: Concentric rings / "O" in circle
- Colors: #2c3e50 (dark), #ffffff (white)
- Font: System fonts (Apple/Segoe UI/Arial)

---

## 💡 Tips

1. **Test in a dev environment first** before applying to production
2. **Take screenshots** of your setup before rebranding (for comparison)
3. **Clear browser cache** after rebranding to see changes immediately
4. **Use incognito mode** to verify without cache issues
5. **Keep this package** for future installations

---

## 📞 Getting Help

If you run into issues:

1. **Check the logs:**
   ```bash
   docker logs your-dashboard-container --tail 50
   ```

2. **Review documentation:**
   - See `ONERING_REBRAND_DOCUMENTATION.md` for detailed steps
   - Check `TROUBLESHOOTING` section

3. **Verify container is running:**
   ```bash
   docker ps | grep wazuh
   ```

4. **Try the manual method:**
   - Follow step-by-step in the documentation
   - This gives you more control

---

## 🎯 Quick Command Reference

```bash
# Run automated rebranding
./rebrand_wazuh.sh

# Check dashboard status
docker ps | grep wazuh.dashboard

# View logs
docker logs wazuh.dashboard --tail 20

# Restart dashboard
docker restart wazuh.dashboard

# Restore original
docker compose up -d --force-recreate wazuh.dashboard

# Access dashboard
# https://localhost:443
# Username: admin
# Password: SecretPassword
```

---

## 📦 Package Contents Summary

- **10 logo files** (SVG format, ~4.5 KB total)
- **1 automated script** (rebrand_wazuh.sh)
- **3 documentation files** (complete guide, quick ref, summary)
- **1 Docker image** (optional, pre-rebranded)

**Total:** Everything needed to rebrand Wazuh to OneRingInc

---

## ✅ Installation Checklist

Before sharing with others or presenting:

- [ ] Wazuh dashboard is running
- [ ] Docker is installed and working
- [ ] You have terminal/command line access
- [ ] Package is extracted to a folder
- [ ] Script has execute permissions (`chmod +x`)

After installation:

- [ ] Login page shows OneRingInc logo
- [ ] Corner shows "O" not "W"
- [ ] Loading screens show "O" spinner
- [ ] Both light and dark themes work
- [ ] Dashboard is accessible at https://localhost:443

---

## 🚀 Ready to Start?

Choose your method:

1. **Super fast?** → Use Option 1 (Docker image)
2. **Want automation?** → Use Option 2 (Script)
3. **Want full control?** → Use Option 3 (Manual)

Any questions? Check the documentation files included in this package!

---

**Enjoy your OneRingInc branded Wazuh dashboard! 🎉**

Created with ❤️ using Claude Code
Version: 1.0
Date: November 8, 2025
