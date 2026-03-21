# OneRing Wazuh - Mobile Threat Detection Platform

A Wazuh-based platform for **mobile security monitoring** on Android devices, specifically designed to detect and prevent **elder scam attacks** through real-time app installation monitoring and threat detection.

## 🎯 Mission

Protect vulnerable populations, particularly elderly users, from mobile-based scams by providing real-time monitoring and alerting of suspicious app installations and activities on Android devices.

---

## 🚀 Quick Start (E2E Setup)

### Prerequisites

Before you begin, ensure you have:

- ✅ **Docker & Docker Compose** installed ([Get Docker](https://docs.docker.com/get-docker/))
- ✅ **Wazuh 4.14.0** Docker deployment ([Official Guide](https://documentation.wazuh.com/current/deployment-options/docker/index.html))
- ✅ **Android Studio** with an emulator OR a physical Android device
- ✅ **ADB (Android Debug Bridge)** installed and in PATH
- ✅ **Python 3** installed

### Step 1: Clone the Repository

```bash
git clone https://github.com/OneRingOSS/onering_wazuh.git
cd onering_wazuh
```

### Step 2: Set Up Wazuh with Mobile Monitoring

#### Option A: Automated Setup (Recommended)

```bash
# Run the automated setup script
./setup_mobile_monitoring.sh

# Follow the prompts to:
# 1. Specify your Wazuh Docker directory
# 2. Automatically copy configs and update docker-compose.yml
# 3. Restart Wazuh with mobile monitoring enabled
```

#### Option B: Manual Setup for New Wazuh Installation

```bash
# Download Wazuh Docker setup
curl -so docker-compose.yml https://packages.wazuh.com/4.14/docker-compose.yml

# Generate certificates
docker-compose -f generate-indexer-certs.yml run --rm generator

# Copy mobile monitoring configs to Wazuh directory
cp mobile_demo/ossec.conf .
cp mobile_demo/local_decoder.xml .
cp mobile_demo/local_rules.xml .

# Add volume mounts to docker-compose.yml (see below)
# Then start Wazuh
docker-compose up -d
```

#### Option C: Manual Setup for Existing Wazuh Installation

```bash
# Navigate to your Wazuh Docker directory
cd /path/to/your/wazuh-docker/single-node

# Copy mobile monitoring configuration files
cp /path/to/onering_wazuh/mobile_demo/ossec.conf .
cp /path/to/onering_wazuh/mobile_demo/local_decoder.xml .
cp /path/to/onering_wazuh/mobile_demo/local_rules.xml .
```

**Add these volume mounts** to your `docker-compose.yml` under the `wazuh.manager` service:

```yaml
services:
  wazuh.manager:
    volumes:
      # ... existing volumes ...
      # Mobile monitoring configuration
      - ./ossec.conf:/var/ossec/etc/ossec.conf:ro
      - ./local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml:ro
      - ./local_rules.xml:/var/ossec/etc/rules/local_rules.xml:ro
```

**Restart Wazuh:**

```bash
docker-compose down
docker-compose up -d

# Wait 30 seconds for services to start, then verify
docker exec <wazuh-manager-container> grep "514/UDP" /var/ossec/logs/ossec.log
# Should show: "Listening on port 514/UDP (syslog)"
```

### Step 3: Start Android Emulator

```bash
# List available emulators
emulator -list-avds

# Start an emulator (replace <avd_name> with your AVD)
emulator -avd <avd_name> &

# Verify emulator is running
adb devices
# Should show: emulator-5554    device
```

### Step 4: Forward Android Logs to Wazuh

```bash
# From the onering_wazuh directory
./mobile_demo/forward_logcat_localhost.sh

# You should see:
# 🚀 Starting logcat forwarding...
#    Emulator: emulator-5554
#    Wazuh: 127.0.0.1:514
#    Press Ctrl+C to stop
```

**Note:** The script monitors logcat and will **automatically exit after detecting the first PACKAGE_ADDED event**. This is by design - you'll need to run it again before each app installation test.

### Step 5: Test the Detection

Install an app on the emulator:

```bash
# Option 1: Install any APK
adb install /path/to/any-app.apk

# Option 2: Install from the emulator's Play Store
# (Just open Play Store in the emulator and install any app)
```

**The forwarding script will detect the event and exit** with:
```
✅ Detected PACKAGE_ADDED event, exiting after sending message
   Package: ...
```

**To monitor another installation**, simply run `./mobile_demo/forward_logcat_localhost.sh` again.

### Step 6: Verify Alerts in Wazuh

**View alerts in the terminal:**

```bash
docker exec <wazuh-manager-container> tail -f /var/ossec/logs/alerts/alerts.json | grep "PACKAGE_ADDED"
```

**Or open the Wazuh Dashboard:**

1. Navigate to: **https://localhost:443** (or your Wazuh server IP)
2. Login with default credentials:
   - Username: `admin`
   - Password: `SecretPassword` (check your docker-compose.yml)
3. Go to: **Security Events** → **Discover**
4. Filter by: `rule.id:100006`
5. You should see alerts for installed packages!

---

## ✨ Key Features

- ✅ **Real-time Android app installation monitoring**
- ✅ **Custom Wazuh decoders** for Android log parsing
- ✅ **High-severity alerts** (level 15) for suspicious apps
- ✅ **Syslog-based log collection** from Android devices
- ✅ **Self-contained setup** - all scripts included
- ✅ **Docker-based deployment** (Wazuh 4.14.0)
- ✅ **OneRingInc dashboard branding** (optional)

---

## 🔧 Project Structure

```
onering_wazuh/
├── mobile_demo/
│   ├── ossec.conf                      # Wazuh config with UDP 514 syslog listener
│   ├── local_decoder.xml               # Android PACKAGE_ADDED decoder
│   ├── local_rules.xml                 # Alert rules (rule 100006)
│   ├── forward_logcat.py               # Python script to forward Android logs
│   ├── forward_logcat_localhost.sh     # Wrapper script for easy execution
│   └── docs/                           # Additional documentation
├── custom-logos/                       # OneRingInc branding assets
├── rebrand_wazuh.sh                    # Dashboard rebranding script
├── LICENSE                             # LGPL-2.0 license
└── README.md                           # This file
```

---

## 🧪 Testing Without Android Device

You can test the pipeline without an Android device:

```bash
# Send a test log via UDP
echo "BackupManagerService: Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.malware flg=0x4000010 (has extras) }" | nc -u -w1 localhost 514

# Check alerts
docker exec <wazuh-manager-container> tail -20 /var/ossec/logs/alerts/alerts.json | grep "com.test.malware"
```

Expected output:
```json
{
  "rule": {
    "level": 15,
    "description": "Malicions Android app installed: com.test.malware",
    "id": "100006"
  },
  "data": {
    "package_name": "com.test.malware"
  }
}
```

---

## 🎨 Optional: Dashboard Branding

Apply OneRingInc branding to the Wazuh dashboard:

```bash
./rebrand_wazuh.sh <wazuh-dashboard-container-name>
```

This replaces 26+ logo files with OneRingInc branding (light/dark themes supported).

---

## 📊 Alert Details

| Rule ID | Level | Description | Trigger |
|---------|-------|-------------|---------|
| 100006 | 15 (High) | Malicious Android app installed | Any PACKAGE_ADDED event detected |

**Alert Fields:**
- `package_name`: Extracted package identifier (e.g., `com.example.app`)
- `decoder`: `android_decoder_03`
- `full_log`: Complete Android log line

---

## 🛡️ Use Cases

### Elder Scam Detection
- Monitor elderly users' devices for suspicious app installations
- Alert caregivers/family when unknown apps are installed
- Track installation patterns over time

### Mobile Security Platform
- Centralized monitoring for multiple Android devices
- Real-time threat detection and alerting
- Historical analysis of app installations

---

## 🔒 Security Considerations

- **Network Security**: Firewall UDP port 514 appropriately
- **Data Privacy**: Android logs may contain sensitive information
- **Authentication**: Use strong Wazuh dashboard credentials
- **Production**: Use VPN or encrypted channels for remote devices

---

## 📖 Additional Documentation

- [`mobile_demo/docs/QUICK_START.md`](mobile_demo/docs/QUICK_START.md) - Detailed setup guide
- [`mobile_demo/docs/WAZUH_CONFIG_CHANGES.md`](mobile_demo/docs/WAZUH_CONFIG_CHANGES.md) - Configuration details
- [`mobile_demo/docs/CONFIG_SUMMARY.md`](mobile_demo/docs/CONFIG_SUMMARY.md) - Technical summary

---

## 🗺️ Roadmap

- [ ] Machine learning-based scam app detection
- [ ] Integration with threat intelligence feeds
- [ ] Multi-device family monitoring dashboard
- [ ] SMS and call log monitoring
- [ ] Automated response actions (app blocking)
- [ ] Mobile app for caregiver alerts

---

## 🤝 Contributing

Contributions welcome! Please submit pull requests or open issues for:
- New mobile threat detection rules
- Additional Android log decoders
- Dashboard improvements
- Documentation enhancements

---

## 📄 License

GNU Library General Public License v2.0 (LGPL-2.0) - See [LICENSE](LICENSE)

---

## 🙏 Acknowledgments

- Built on [Wazuh](https://wazuh.com/) - Open Source Security Platform
- Inspired by the need to protect vulnerable populations from mobile scams

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/OneRingOSS/onering_wazuh/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OneRingOSS/onering_wazuh/discussions)

---

**Protecting those who need it most, one device at a time.** 🛡️
