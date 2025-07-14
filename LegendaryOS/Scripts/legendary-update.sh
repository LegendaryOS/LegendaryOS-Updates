#!/bin/bash
# Legendary Update Script for openMamba
# Autor: LegendaryOS Team
# Wersja: 0.1

# Kolory ANSI
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

LOG_FILE="/tmp/legendary-update.log"
LOCAL_RELEASE_FILE="/home/$USER/.LegendaryOS/.release"
GITHUB_REPO="https://github.com/LegendaryOS/LegendaryOS-Updates.git"
TMP_DIR="/tmp/LegendaryOS-Updates"

# Domyślne flagi
DO_FIRMWARE=true
DO_DNF=true
DO_FLATPAK=true
DO_SNAP=true

# Funkcja spinnera (płynniejszy, z kolorami)
spinner() {
    local pid=$1
    local delay=0.05
    local frames=(
        " <=>         "
        "         <=> "
        " <==>        "
        "        <==> "
        " <===>       "
        "       <===> "
        " <====>      "
        "      <====> "
        " <=====>     "
        "     <=====> "
        " <======>    "
        "    <======> "
        " <=======>   "
        "   <=======> "
        " <========>  "
        "   <=======> "
        " <=======>   "
        "   <=======> "
        " <======>    "
        "    <======> "
        " <=====>     "
        "     <=====> "
        " <====>      "
        "      <====> "
        " <===>       "
        "       <===> "
        " <==>        "
        "        <==> "
        " <=>         "
        "         <=> "
    )

    while ps -p $pid &>/dev/null; do
        for frame in "${frames[@]}"; do
            echo -ne "\r${CYAN}>>> $frame Processing...${NC}"
            sleep $delay
        done
    done
    echo -ne "\r${GREEN}>>> Completed.                    ${NC}\n"
}

# Funkcja do wyświetlania nagłówka
print_header() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         LegendaryOS Full Update       ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Log file: ${LOG_FILE}${NC}\n"
}

# Sprawdzenie uprawnień sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script requires administrator privileges. Run with sudo.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi

# Przetwarzanie argumentów
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-firmware) DO_FIRMWARE=false ;;
        --no-flatpak) DO_FLATPAK=false ;;
        --no-snap) DO_SNAP=false ;;
        *) echo -e "${RED}Unknown argument: $1${NC}" ;;
    esac
    shift
done

# Czyszczenie logu
> "$LOG_FILE"

print_header

# Tabela statusu opcji aktualizacji (ulepszona, z większym kontrastem)
echo -e "${YELLOW}Update Options Status:${NC}"
echo -e "${BLUE}┌────────────────────────┬──────────────┐${NC}"
echo -e "${BLUE}│ Option                │ Status       │${NC}"
echo -e "${BLUE}├────────────────────────┼──────────────┤${NC}"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "Firmware" "$(if $DO_FIRMWARE; then echo "${GREEN}Enabled${NC}"; else echo "${RED}Disabled${NC}"; fi)"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "DNF" "${GREEN}Enabled${NC}"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "Flatpak" "$(if $DO_FLATPAK; then echo "${GREEN}Enabled${NC}"; else echo "${RED}Disabled${NC}"; fi)"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "Snap" "$(if $DO_SNAP; then echo "${GREEN}Enabled${NC}"; else echo "${RED}Disabled${NC}"; fi)"
echo -e "${BLUE}└────────────────────────┴──────────────┘${NC}\n"

backup_files() {
    echo -e "${GREEN}Creating backup of configuration files...${NC}"
    BACKUP_DIR="/home/$USER/.LegendaryOS/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp -r /etc/dnf "$BACKUP_DIR/" 2>/dev/null
    cp -r /etc/fwupd "$BACKUP_DIR/" 2>/dev/null
    cp -r /home/$USER/.config "$BACKUP_DIR/" 2>/dev/null
    echo -e "${GREEN}Backup created at $BACKUP_DIR${NC}" | tee -a "$LOG_FILE"
}

# Backup
backup_files

if $DO_FIRMWARE; then
    echo -e "\n${CYAN}Updating firmware...${NC}"
    (fwupdmgr refresh >> "$LOG_FILE" 2>&1 && \
     fwupdmgr get-updates >> "$LOG_FILE" 2>&1 && \
     fwupdmgr update -y >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo -e "${YELLOW}Skipped firmware update (--no-firmware)${NC}" | tee -a "$LOG_FILE"
fi

echo -e "\n${CYAN}Updating DNF packages...${NC}"
(dnf check-update >> "$LOG_FILE" 2>&1 && \
 dnf upgrade -y >> "$LOG_FILE" 2>&1) &
spinner $!

echo -e "\n${CYAN}Cleaning DNF cache...${NC}"
(dnf clean all >> "$LOG_FILE" 2>&1) &
spinner $!

echo -e "\n${CYAN}Removing orphaned packages...${NC}"
ORPHANED=$(dnf list --extras | awk 'NR>1 {print $1}')
if [[ -n "$ORPHANED" ]]; then
    (dnf remove -y $ORPHANED >> "$LOG_FILE" 2>&1)在上
    spinner $!
else
    echo -e "${YELLOW}No orphaned packages to remove.${NC}" | tee -a "$LOG_FILE"
fi

if $DO_FLATPAK; then
    echo -e "\n${CYAN}Updating Flatpak...${NC}"
    (flatpak update -y >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo -e "${YELLOW}Skipped Flatpak update (--no-flatpak)${NC}" | tee -a "$LOG_FILE"
fi

if $DO_SNAP; then
    echo -e "\n${CYAN}Updating Snap...${NC}"
    (snap refresh >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo -e "${YELLOW}Skipped Snap update (--no-snap)${NC}" | tee -a "$LOG_FILE"
fi

# Aktualizacja LegendaryOS z repozytorium GitHub/SourceForge
echo -e "\n${CYAN}Checking for LegendaryOS version...${NC}"
LATEST_ISO=$(curl -s "https://sourceforge.net/projects/legendaryos/files/" | \
    grep -oP 'LegendaryOS-(Official|Blue)-V[0-9]+\.[0-9]+(\.[0-9]+)?\.ISO' | sort -V | tail -n1)

if [[ -z "$LATEST_ISO" ]]; then
    echo -e "${RED}Failed to retrieve latest version from SourceForge.${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${GREEN}Latest SourceForge version: $LATEST_ISO${NC}" | tee -a "$LOG_FILE"

    if [[ ! -f "$LOCAL_RELEASE_FILE" ]]; then
        echo -e "${YELLOW}Local version file $LOCAL_RELEASE_FILE not found. Assuming no version.${NC}" | tee -a "$LOG_FILE"
        LOCAL_VERSION="none"
    else
        LOCAL_VERSION=$(head -n1 "$LOCAL_RELEASE_FILE")
    fi

    echo -e "${GREEN}Local version: $LOCAL_VERSION${NC}" | tee -a "$LOG_FILE"

    extract_version() {
        echo "$1" | grep -oP 'V[0-9]+\.[0-9]+(\.[0-9]+)?' | tr -d 'V'
    }

    local_ver_num=$(extract_version "$LOCAL_VERSION")
    latest_ver_num=$(extract_version "$LATEST_ISO")

    vercmp() {
        local IFS=.
        local i ver1=($1) ver2=($2)
        for ((i=${#ver1[@]}; i<3; i++)); do ver1[i]=0; done
        for ((i=${#ver2[@]}; i<3; i++)); do ver2[i]=0; done

        for ((i=0; i<3; i++)); do
            if ((10#${ver1[i]} > 10#${ver2[i]})); then
                echo 1
                return
            elif ((10#${ver1[i]} < 10#${ver2[i]})); then
                echo -1
                return
            fi
        done
        echo 0
    }

    cmp_result=$(vercmp "$local_ver_num" "$latest_ver_num")

    if [[ "$local_ver_num" == "none" || $cmp_result -lt 0 ]]; then
        echo -e "\n${CYAN}Newer LegendaryOS version available. Updating...${NC}" | tee -a "$LOG_FILE"

        rm -rf "$TMP_DIR"
        git clone "$GITHUB_REPO" "$TMP_DIR" >> "$LOG_FILE" 2>&1

        if [[ ! -d "$TMP_DIR" ]]; then
            echo -e "${RED}Failed to clone repository.${NC}" | tee -a "$LOG_FILE"
            exit 1
        fi

        chmod +x "$TMP_DIR/unpack.sh"
        echo -e "${CYAN}Running unpack.sh with sudo...${NC}" | tee -a "$LOG_FILE"
        sudo "$TMP_DIR/unpack.sh" >> "$LOG_FILE" 2>&1

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}LegendaryOS update completed successfully.${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}Error during LegendaryOS update.${NC}" | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        echo -e "${GREEN}Your LegendaryOS version ($LOCAL_VERSION) is up to date.${NC}" | tee -a "$LOG_FILE"
    fi
fi

# Aktualizacja kernel TKG
echo -e "\n${CYAN}Updating TKG Kernel...${NC}"
/usr/bin/update-tkg-kernel.sh >> "$LOG_FILE" 2>&1

# Tabela podsumowująca (ulepszona z większym kontrastem i stylizacją)
echo -e "\n${PURPLE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║               Update Summary                        ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════╝${NC}"
echo -e "${BLUE}┌────────────────────────┬──────────────┐${NC}"
echo -e "${BLUE}│ Step                  │ Status       │${NC}"
echo -e "${BLUE}├────────────────────────┼──────────────┤${NC}"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "Firmware" "$(if $DO_FIRMWARE; then echo "${GREEN}Completed${NC}"; else echo "${RED}Skipped${NC}"; fi)"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "DNF" "${GREEN}Completed${NC}"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "Flatpak" "$(if $DO_FLATPAK; then echo "${GREEN}Completed${NC}"; else echo "${RED}Skipped${NC}"; fi)"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "Snap" "$(if $DO_SNAP; then echo "${GREEN}Completed${NC}"; else echo "${RED}Skipped${NC}"; fi)"
printf "${BLUE}│ %-21s │ %-12s │${NC}\n" "TKG Kernel" "${GREEN}Completed${NC}"
echo -e "${BLUE}└────────────────────────┴──────────────┘${NC}\n"

echo -e "${GREEN}Update process completed successfully.${NC}"
echo -e "${YELLOW}Log saved at $LOG_FILE${NC}"

# Menu końcowe (ulepszone, bez emotek)
echo -e "\n${YELLOW}Select an option:${NC}"
echo -e "${CYAN}┌───────────────────────────────┐${NC}"
echo -e "${CYAN}│ Shutdown  Reboot  Log out    │${NC}"
echo -e "${CYAN}│ Exit      Try again          │${NC}"
echo -e "${CYAN}└───────────────────────────────┘${NC}"
read -n1 -s choice
echo ""

case $choice in
    s|S)
        echo -e "${GREEN}Shutting down system...${NC}"
        systemctl poweroff
        ;;
    r|R)
        echo -e "${GREEN}Rebooting system...${NC}"
        systemctl reboot
        ;;
    l|L)
        echo -e "${GREEN}Logging out user...${NC}"
        pkill -KILL -u "$USER"
        ;;
    e|E)
        echo -e "${GREEN}Exiting script.${NC}"
        exit 0
        ;;
    t|T)
        echo -e "${GREEN}Restarting script...${NC}"
        exec "$0"
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        exit 1
        ;;
esac
