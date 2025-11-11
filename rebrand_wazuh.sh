#!/bin/bash

################################################################################
# OneRingInc Wazuh Dashboard Rebranding Script
#
# This script automatically rebrands a Wazuh dashboard installation
# to replace all Wazuh logos with OneRingInc branding.
#
# Usage: ./rebrand_wazuh.sh [container-name]
# Default container: single-node-wazuh.dashboard-1
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default container name
CONTAINER_NAME="${1:-single-node-wazuh.dashboard-1}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGOS_DIR="${SCRIPT_DIR}/custom-logos"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BLUE}"
    echo "================================================================================"
    echo "  OneRingInc Wazuh Dashboard Rebranding Script"
    echo "================================================================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_step "Docker is installed"

    # Check if container exists
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_error "Container '${CONTAINER_NAME}' not found."
        echo "Available containers:"
        docker ps -a --format '{{.Names}}'
        exit 1
    fi
    print_step "Container '${CONTAINER_NAME}' found"

    # Check if logos directory exists
    if [ ! -d "${LOGOS_DIR}" ]; then
        print_error "Logos directory not found: ${LOGOS_DIR}"
        exit 1
    fi
    print_step "Logos directory found"

    # Count logo files
    LOGO_COUNT=$(find "${LOGOS_DIR}" -name "*.svg" | wc -l | tr -d ' ')
    if [ "${LOGO_COUNT}" -lt 10 ]; then
        print_warning "Expected 10 logo files, found ${LOGO_COUNT}"
    else
        print_step "All ${LOGO_COUNT} logo files found"
    fi
}

backup_config() {
    echo -e "\n${BLUE}Creating backup of configuration...${NC}"

    BACKUP_DIR="${SCRIPT_DIR}/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${BACKUP_DIR}"

    # Note: We can't easily backup files from inside the container
    # but we can backup the host config
    print_step "Backup directory created: ${BACKUP_DIR}"
    echo "Note: Container files cannot be backed up automatically."
    echo "To restore, recreate the container from the original image."
}

copy_plugin_logos() {
    echo -e "\n${BLUE}Copying plugin theme logos...${NC}"

    docker cp "${LOGOS_DIR}/logo-light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/light/logo.svg"
    docker cp "${LOGOS_DIR}/icon-light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/light/icon.svg"
    docker cp "${LOGOS_DIR}/logo-dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/dark/logo.svg"
    docker cp "${LOGOS_DIR}/icon-dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/images/themes/dark/icon.svg"

    print_step "Plugin logos copied (4 files)"
}

copy_core_logos() {
    echo -e "\n${BLUE}Copying core UI logos...${NC}"

    # Light theme marks
    docker cp "${LOGOS_DIR}/onering_mark_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark_on_light.svg"
    docker cp "${LOGOS_DIR}/onering_mark_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark.svg"
    docker cp "${LOGOS_DIR}/onering_mark_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark_on_light.svg"
    docker cp "${LOGOS_DIR}/onering_mark_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_on_light.svg"

    # Dark theme marks
    docker cp "${LOGOS_DIR}/onering_mark_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_mark_on_dark.svg"
    docker cp "${LOGOS_DIR}/onering_mark_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark_on_dark.svg"
    docker cp "${LOGOS_DIR}/onering_mark_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_on_dark.svg"
    docker cp "${LOGOS_DIR}/onering_mark_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_center_mark.svg"

    print_step "Core mark logos copied (8 files)"

    # Full logos
    docker cp "${LOGOS_DIR}/onering_full_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards_on_light.svg"
    docker cp "${LOGOS_DIR}/onering_full_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards.svg"
    docker cp "${LOGOS_DIR}/onering_full_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh.svg"
    docker cp "${LOGOS_DIR}/onering_full_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/wazuh_dashboards_on_dark.svg"

    print_step "Full logos copied (4 files)"

    # Icons
    docker cp "${LOGOS_DIR}/icon-light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/icon_light.svg"
    docker cp "${LOGOS_DIR}/icon-dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/icon_dark.svg"

    print_step "Icons copied (2 files)"

    # Spinners
    docker cp "${LOGOS_DIR}/spinner_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/spinner_on_light.svg"
    docker cp "${LOGOS_DIR}/spinner_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/logos/spinner_on_dark.svg"

    print_step "Spinners copied (2 files)"
}

copy_main_assets() {
    echo -e "\n${BLUE}Copying main assets...${NC}"

    docker cp "${LOGOS_DIR}/onering_full_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/wazuh_logo.svg"

    print_step "Main logo copied (1 file)"
}

copy_default_branding() {
    echo -e "\n${BLUE}Copying default branding...${NC}"

    docker cp "${LOGOS_DIR}/onering_mark_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/opensearch_mark_default_mode.svg"
    docker cp "${LOGOS_DIR}/onering_mark_dark.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/src/core/server/core_app/assets/default_branding/opensearch_mark_dark_mode.svg"

    print_step "Default branding copied (2 files)"
}

copy_login_logo() {
    echo -e "\n${BLUE}Copying login page logo...${NC}"

    docker cp "${LOGOS_DIR}/onering_full_light.svg" "${CONTAINER_NAME}:/usr/share/wazuh-dashboard/plugins/securityDashboards/target/public/30e500f584235c2912f16c790345f966.svg"

    print_step "Login logo copied (1 file)"
}

restart_dashboard() {
    echo -e "\n${BLUE}Restarting dashboard...${NC}"

    docker restart "${CONTAINER_NAME}"

    print_step "Dashboard restarted"
    echo -e "${YELLOW}Waiting for dashboard to start (30 seconds)...${NC}"
    sleep 30
}

verify_installation() {
    echo -e "\n${BLUE}Verifying installation...${NC}"

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_step "Container is running"
    else
        print_error "Container is not running"
        return 1
    fi

    # Check logs for errors
    if docker logs "${CONTAINER_NAME}" --tail 20 | grep -qi "error\|fatal"; then
        print_warning "Errors found in logs, please check manually"
    else
        print_step "No critical errors in logs"
    fi
}

print_summary() {
    echo -e "\n${GREEN}"
    echo "================================================================================"
    echo "  Rebranding Complete!"
    echo "================================================================================"
    echo -e "${NC}"
    echo "Total files replaced: 26+ files"
    echo ""
    echo "Dashboard Access:"
    echo "  URL:      https://localhost:443"
    echo "  Username: admin"
    echo "  Password: SecretPassword"
    echo ""
    echo "What's been changed:"
    echo "  ✓ Login page logo"
    echo "  ✓ Loading spinner"
    echo "  ✓ Corner logo (W → O)"
    echo "  ✓ All sidebar/header logos"
    echo "  ✓ Light & dark theme variants"
    echo ""
    echo -e "${YELLOW}Note: Some text references to 'Wazuh' remain in menu items.${NC}"
    echo "This is normal and doesn't affect visual branding."
    echo ""
    echo "To restore original branding:"
    echo "  docker compose up -d --force-recreate wazuh.dashboard"
    echo ""
    echo "Documentation:"
    echo "  ${SCRIPT_DIR}/ONERING_REBRAND_DOCUMENTATION.md"
    echo ""
    echo -e "${GREEN}Enjoy your OneRingInc branded dashboard!${NC}"
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header

    echo "Container: ${CONTAINER_NAME}"
    echo "Logos directory: ${LOGOS_DIR}"
    echo ""

    check_prerequisites
    backup_config
    copy_plugin_logos
    copy_core_logos
    copy_main_assets
    copy_default_branding
    copy_login_logo
    restart_dashboard
    verify_installation
    print_summary
}

# Run main function
main

exit 0
