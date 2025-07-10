#!/bin/bash

# Legendary Update Script
# Autor: LegendaryOS Team
# Wersja: 0.1

LOG_FILE="/tmp/legendary-update.log"

# Czyszczenie logu przed uruchomieniem
> "$LOG_FILE"

# Funkcja spinnera (falujący pasek)
spinner() {
    local pid=$1
    local delay=0.1
    local frames=(
        "[ <=>         ]"
        "[ <==>        ]"
        "[ <===>       ]"
        "[ <====>      ]"
        "[ <=====>     ]"
        "[ <======>    ]"
        "[ <=======>   ]"
        "[ <========>  ]"
        "[ <=======>   ]"
        "[ <======>    ]"
        "[ <=====>     ]"
        "[ <====>      ]"
        "[ <===>       ]"
        "[ <==>        ]"
        "[ <=>         ]"
    )

    while ps -p $pid &>/dev/null; do
        for frame in "${frames[@]}"; do
            echo -ne "\r>>> $frame "
            sleep $delay
        done
    done
    echo -ne "\r>>> Zakończono.             \n"
}

# Nagłówek
clear
echo "====== [ LegendaryOS FULL UPDATE ] ======"
echo "Log zapisywany w $LOG_FILE"

### Aktualizacja firmware ###
echo -e "\n>>> Aktualizacja firmware..."
(sudo fwupdmgr refresh >> "$LOG_FILE" 2>&1 && \
sudo fwupdmgr get-updates >> "$LOG_FILE" 2>&1 && \
sudo fwupdmgr update -y >> "$LOG_FILE" 2>&1) &
spinner $!

### Aktualizacja zypper ###
echo -e "\n>>> Aktualizacja pakietów zypper..."
(sudo zypper refresh >> "$LOG_FILE" 2>&1 && \
sudo zypper update -y >> "$LOG_FILE" 2>&1) &
spinner $!

### Autoremove ###
echo -e "\n>>> Usuwanie niepotrzebnych pakietów..."
(sudo zypper remove --clean-deps $(zypper packages --orphaned | awk 'NR>4 {print $3}') >> "$LOG_FILE" 2>&1) &
spinner $!

### Aktualizacja Flatpak ###
echo -e "\n>>> Aktualizacja Flatpak..."
(flatpak update -y >> "$LOG_FILE" 2>&1) &
spinner $!

### Aktualizacja Snap ###
echo -e "\n>>> Aktualizacja Snap..."
(sudo snap refresh >> "$LOG_FILE" 2>&1) &
spinner $!

### Skrypt aktualizacji aplikacji LegendaryOS ###

LOCAL_RELEASE_FILE="/home/$USER/.LegendaryOS/.release"
GITHUB_REPO="https://github.com/LegendaryOS/LegendaryOS-Updates.git"
TMP_DIR="/tmp/LegendaryOS-Updates"

echo -e "\n>>> Sprawdzanie dostępnej wersji LegendaryOS..."

# Pobranie najnowszego pliku ISO z SourceForge
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

### Skrypt aktualizacji kernel TKG ###
echo -e "\n>>> Aktualizacja TKG Kernel..."
/usr/bin/update-tkg-kernel.sh >> "$LOG_FILE" 2>&1

# Zakończenie i wybór akcji
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
