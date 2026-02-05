# OneRing Wazuh - Mobile Threat Detection Platform

A Wazuh fork focused on enabling **mobile security monitoring** for Android devices, specifically designed to detect and prevent **elder scam attacks** through real-time app installation monitoring and threat detection.

## 🎯 Mission

Protect vulnerable populations, particularly elderly users, from mobile-based scams by providing real-time monitoring and alerting of suspicious app installations and activities on Android devices.

## 🔍 Overview

This project extends Wazuh's security monitoring capabilities to Android mobile devices, enabling:

- **Real-time Android app installation monitoring**
- **Suspicious app detection and alerting**
- **Syslog-based log collection from Android devices**
- **Custom decoders and rules for mobile threat detection**
- **High-severity alerts for potential scam applications**

## ✨ Key Features

### Mobile Security Monitoring
- ✅ Monitor Android app installations in real-time
- ✅ Detect `PACKAGE_ADDED` events via syslog
- ✅ Custom Wazuh decoders for Android log parsing
- ✅ High-severity alerts (level 15) for malicious apps
- ✅ JSON archive logging for comprehensive event tracking

### Dashboard Customization
- ✅ Custom OneRingInc branding for Wazuh Dashboard
- ✅ Automated rebranding script
- ✅ Light/dark theme support
- ✅ Professional "O" ring icon branding

### Easy Deployment
- ✅ Docker-based setup (Wazuh 4.13.0)
- ✅ Automated configuration scripts
- ✅ Version-controlled configurations
- ✅ Comprehensive documentation

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Wazuh 4.13.0 (single-node or multi-node setup)
- Android device with syslog capability
- Network connectivity between Android device and Wazuh server

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/OneRingOSS/onering_wazuh.git
   cd onering_wazuh
   ```

2. **Deploy mobile monitoring configuration**
   ```bash
   cd mobile_demo

   # Copy configuration files to your Wazuh installation
   cp ossec.conf /path/to/your/wazuh/
   cp local_decoder.xml /path/to/your/wazuh/
   cp local_rules.xml /path/to/your/wazuh/
   ```

3. **Update docker-compose.yml**

   Add volume mounts to your Wazuh manager service:
   ```yaml
   services:
     wazuh.manager:
       volumes:
         - ./ossec.conf:/var/ossec/etc/ossec.conf:ro
         - ./local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml:ro
         - ./local_rules.xml:/var/ossec/etc/rules/local_rules.xml:ro
   ```

4. **Restart Wazuh**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

5. **Configure Android device**

   Install a syslog app on your Android device and configure:
   - **Host**: Your Wazuh server IP
   - **Port**: 514
   - **Protocol**: UDP

## 📖 Documentation

### Mobile Monitoring
- [`mobile_demo/docs/QUICK_START.md`](mobile_demo/docs/QUICK_START.md) - Step-by-step setup guide
- [`mobile_demo/docs/WAZUH_CONFIG_CHANGES.md`](mobile_demo/docs/WAZUH_CONFIG_CHANGES.md) - Detailed configuration documentation
- [`mobile_demo/docs/CONFIG_SUMMARY.md`](mobile_demo/docs/CONFIG_SUMMARY.md) - Technical configuration summary

### Dashboard Branding
- [`rebrand_wazuh.sh`](rebrand_wazuh.sh) - Automated dashboard rebranding script
- [`custom-logos/`](custom-logos/) - OneRingInc logo assets

## 🔧 Configuration Files

### Core Components

| File | Purpose |
|------|---------|
| `mobile_demo/ossec.conf` | Main Wazuh configuration with syslog reception |
| `mobile_demo/local_decoder.xml` | Android log decoder for PACKAGE_ADDED events |
| `mobile_demo/local_rules.xml` | Alert rules for suspicious app installations |
| `mobile_demo/forward_logcat_localhost.sh` | Script to forward Android logs |

## 🎨 Dashboard Branding

Rebrand the Wazuh dashboard with OneRingInc branding:

```bash
./rebrand_wazuh.sh [container-name]
```

The script automatically:
- Replaces 26+ logo files (SVG)
- Updates login page, sidebar, header, and loading spinners
- Supports both light and dark themes
- Restarts the dashboard container

## 🛡️ Use Cases

### Elder Scam Detection
Monitor elderly users' Android devices for:
- Installation of known scam applications
- Suspicious banking or payment apps
- Fake tech support applications
- Phishing app installations

### Mobile Security Platform
Build a comprehensive mobile security solution:
- Real-time threat detection
- Centralized monitoring dashboard
- Alert notifications for caregivers/family
- Historical analysis of app installations

## 🧪 Testing

Test the mobile monitoring setup:

```bash
# Send a test Android log
echo "Received broadcast Intent { act=android.intent.action.PACKAGE_ADDED dat=package:com.test.app }" | nc -u -w1 localhost 514

# Check for alerts in Wazuh dashboard
# Navigate to: Security Events > Discover
# Filter by: rule.id:100006
```

## 📊 Alert Levels

| Level | Severity | Description |
|-------|----------|-------------|
| 15 | High | Malicious app installation detected |
| 12 | Medium | Suspicious app installation |
| 3 | Low | Normal app installation logged |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- New mobile threat detection rules
- Additional Android log decoders
- Dashboard improvements
- Documentation enhancements


## 🔒 Security Considerations

- **Network Security**: Ensure syslog traffic (UDP 514) is properly firewalled
- **Data Privacy**: Mobile logs may contain sensitive information - handle appropriately
- **Authentication**: Use strong credentials for Wazuh dashboard access
- **Encryption**: Consider VPN or encrypted channels for production deployments

## 📋 System Requirements

- **Server**: 4GB RAM minimum, 8GB recommended
- **Storage**: 20GB minimum for logs and indices
- **Network**: Stable connection between Android devices and Wazuh server
- **Docker**: Version 20.10+ with Docker Compose

## 🗺️ Roadmap

- [ ] Machine learning-based scam app detection
- [ ] Integration with threat intelligence feeds
- [ ] Multi-device family monitoring dashboard
- [ ] SMS and call log monitoring
- [ ] Automated response actions (app blocking)
- [ ] Mobile app for caregivers/family alerts

## 📄 License

This project is licensed under the GNU Library General Public License v2.0 (LGPL-2.0).
See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on [Wazuh](https://wazuh.com/) - Open Source Security Platform
- Inspired by the need to protect vulnerable populations from mobile scams
- Community contributions and feedback

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/OneRingOSS/onering_wazuh/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OneRingOSS/onering_wazuh/discussions)
- **Documentation**: See `mobile_demo/docs/` directory

## 🌟 Project Status

**Active Development** - This project is under active development. Contributions, bug reports, and feature requests are welcome!

---

**Protecting those who need it most, one device at a time.** 🛡️

*OneRing Wazuh - Mobile Security for Elder Protection*
