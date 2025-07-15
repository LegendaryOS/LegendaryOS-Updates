#!/bin/bash
# Legendary Update Script
# Autor: LegendaryOS Team
# Wersja: 0.1

LOG_FILE="/tmp/legendary-update.log"
LOCAL_RELEASE_FILE="/home/$USER/.LegendaryOS/.release"
GITHUB_REPO="https://github.com/LegendaryOS/LegendaryOS-Updates.git"
TMP_DIR="/tmp/LegendaryOS-Updates"

# Domyślne flagi
DO_FIRMWARE=true
DO_ZYPPER=true
DO_FLATPAK=true
# DO_SNAP usunięte

# Funkcja spinnera (falujący pasek)
spinner() {
    local pid=$1
    local delay=0.1
    local frames=(
        "[ <=>         ]"
        "[         <=> ]"
        "[ <==>        ]"
        "[        <==> ]"
        "[ <===>       ]"
        "[       <===> ]"
        "[ <====>      ]"
        "[      <====> ]"
        "[ <=====>     ]"
        "[     <=====> ]"
        "[ <======>    ]"
        "[    <======> ]"
        "[ <=======>   ]"
        "[   <=======> ]"
        "[ <========>  ]"
        "[   <=======> ]"
        "[ <=======>   ]"
        "[   <=======> ]"
        "[ <======>    ]"
        "[    <======> ]"
        "[ <=====>     ]"
        "[     <=====> ]"
        "[ <====>      ]"
        "[      <====> ]"
        "[ <===>       ]"
        "[       <===> ]"
        "[ <==>        ]"
        "[        <==> ]"
        "[ <=>         ]"
        "[         <=> ]"
    )

    while ps -p $pid &>/dev/null; do
        for frame in "${frames[@]}"; do
            echo -ne "\r>>> $frame "
            sleep $delay
        done
    done
    echo -ne "\r>>> Zakończono.             \n"
}

# Sprawdzenie uprawnień sudo
if [[ $EUID -ne 0 ]]; then
    echo "Ten skrypt wymaga uprawnień administratora. Uruchom ponownie przez sudo." | tee -a "$LOG_FILE"
    exit 1
fi

# Przetwarzanie argumentów
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-firmware) DO_FIRMWARE=false ;;
        --no-pacman) DO_ZYPPER=false ;;
        --no-flatpak) DO_FLATPAK=false ;;
        # --no-snap usunięte
        *) echo "Nieznany argument: $1" ;;
    esac
    shift
done

# Czyszczenie logu
> "$LOG_FILE"

clear
echo "====== [ LegendaryOS FULL UPDATE ] ======"
echo "Log zapisywany w $LOG_FILE"

backup_files() {
    echo -e "\n>>> Tworzę kopię zapasową ważnych plików konfiguracyjnych..."
    BACKUP_DIR="tmp/Legendary-Update-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    # Dodaj pliki do backupu poniżej
    cp -r /etc/zypp "$BACKUP_DIR/" 2>/dev/null
    cp -r /etc/fwupd "$BACKUP_DIR/" 2>/dev/null
    cp -r /home/$USER/.config "$BACKUP_DIR/" 2>/dev/null
    echo "Backup utworzony w $BACKUP_DIR" | tee -a "$LOG_FILE"
}

# Backup
backup_files

if $DO_FIRMWARE; then
    echo -e "\n>>> Aktualizacja firmware..."
    (fwupdmgr refresh >> "$LOG_FILE" 2>&1 && \
     fwupdmgr get-updates >> "$LOG_FILE" 2>&1 && \
     fwupdmgr update -y >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo "Pominięto aktualizację firmware (--no-firmware)" | tee -a "$LOG_FILE"
fi

if $DO_ZYPPER; then
    echo -e "\n>>> Aktualizacja pakietów zypper..."
    (zypper refresh >> "$LOG_FILE" 2>&1 && \
     zypper update -y >> "$LOG_FILE" 2>&1) &
    spinner $!

    echo -e "\n>>> Czyszczenie cache zypper..."
    (zypper clean --all >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo "Pominięto aktualizację zypper (--no-zypper)" | tee -a "$LOG_FILE"
fi

echo -e "\n>>> Usuwanie niepotrzebnych pakietów orphan..."
ORPHANED=$(zypper packages --orphaned | awk 'NR>4 {print $3}')
if [[ -n "$ORPHANED" ]]; then
    (zypper remove --clean-deps -y $ORPHANED >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo "Brak niepotrzebnych pakietów do usunięcia." | tee -a "$LOG_FILE"
fi

if $DO_FLATPAK; then
    echo -e "\n>>> Aktualizacja Flatpak..."
    (flatpak update -y >> "$LOG_FILE" 2>&1) &
    spinner $!
else
    echo "Pominięto aktualizację Flatpak (--no-flatpak)" | tee -a "$LOG_FILE"
fi

# Usunięto sekcję Snap

# Aktualizacja LegendaryOS z repozytorium GitHub/SourceForge
echo -e "\n>>> Sprawdzanie dostępnej wersji LegendaryOS..."

LATEST_ISO=$(curl -s "https://sourceforge.net/projects/legendaryos/files/" | \
    grep -oP 'LegendaryOS-(Official|Blue)-V[0-9]+\.[0-9]+(\.[0-9]+)?\.ISO' | sort -V | tail -n1)

if [[ -z "$LATEST_ISO" ]]; then
    echo "Nie udało się pobrać najnowszej wersji z SourceForge." | tee -a "$LOG_FILE"
else
    echo "Najnowsza wersja na SourceForge: $LATEST_ISO" | tee -a "$LOG_FILE"

    if [[ ! -f "$LOCAL_RELEASE_FILE" ]]; then
        echo "Brak lokalnego pliku wersji $LOCAL_RELEASE_FILE. Zakładam brak wersji." | tee -a "$LOG_FILE"
        LOCAL_VERSION="none"
    else
        LOCAL_VERSION=$(head -n1 "$LOCAL_RELEASE_FILE")
    fi

    echo "Lokalna wersja: $LOCAL_VERSION" | tee -a "$LOG_FILE"

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
        echo -e "\n>>> Dostępna jest nowsza wersja LegendaryOS. Aktualizuję..." | tee -a "$LOG_FILE"

        rm -rf "$TMP_DIR"
        git clone "$GITHUB_REPO" "$TMP_DIR" >> "$LOG_FILE" 2>&1

        if [[ ! -d "$TMP_DIR" ]]; then
            echo "Błąd klonowania repozytorium." | tee -a "$LOG_FILE"
            exit 1
        fi

        chmod +x "$TMP_DIR/unpack.sh"
        echo "Uruchamiam skrypt unpack.sh z sudo..." | tee -a "$LOG_FILE"
        sudo "$TMP_DIR/unpack.sh" >> "$LOG_FILE" 2>&1

        if [[ $? -eq 0 ]]; then
            echo "Aktualizacja LegendaryOS zakończona sukcesem." | tee -a "$LOG_FILE"
        else
            echo "Błąd podczas aktualizacji LegendaryOS." | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        echo "Twoja wersja LegendaryOS ($LOCAL_VERSION) jest najnowsza. Aktualizacja nie jest potrzebna." | tee -a "$LOG_FILE"
    fi
fi

# Aktualizacja kernel TKG
echo -e "\n>>> Aktualizacja TKG Kernel..."
/usr/bin/update-tkg-kernel.sh >> "$LOG_FILE" 2>&1

echo -e "\n========================================="
echo "Aktualizacja zakończona."
echo "Log zapisany w $LOG_FILE"

echo -e "\nWybierz opcję:"
echo "(S)hutdown"
echo "(R)eboot"
echo "(L)og out"
echo "(E)xit"
echo "(T)ry again"

read -n1 -s choice
echo ""

case $choice in
    s|S)
        echo "Wyłączanie systemu..."
        systemctl poweroff
        ;;
    r|R)
        echo "Restartowanie systemu..."
        systemctl reboot
        ;;
    l|L)
        echo "Wylogowywanie użytkownika..."
        pkill -KILL -u "$USER"
        ;;
    e|E)
        echo "Wyjście ze skryptu."
        exit 0
        ;;
    t|T)
        echo "Ponowne uruchamianie skryptu..."
        exec "$0"
        ;;
    *)
        echo "Nieznana opcja. Wyjście."
        exit 1
        ;;
esac
