#!/bin/bash

# LegendaryOS Full Update Script
# Autor: Michał (dla LegendaryOS)
# Wersja: 1.4 openSUSE, bez emotek, z logowaniem i falującym spinnerem

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
echo -e "\n>>> Aktualizacja aplikacji LegendaryOS..."
/usr/bin/Update-Legendary-Apps.sh >> "$LOG_FILE" 2>&1

### Skrypt aktualizacji kernel TKG ###
echo -e "\n>>> Aktualizacja TKG Kernel..."
/usr/bin/update-tkg-kernel.sh >> "$LOG_FILE" 2>&1

# Zakończenie i wybór akcji
echo -e "\n========================================="
echo "Aktualizacja zakończona."
echo "Log zapisany w $LOG_FILE"

echo -e "\nWybierz opcję:"
echo "(s) Shutdown"
echo "(r) Reboot"
echo "(l) Log out"
echo "(e) Exit"
echo "(t) Try again"

# Wczytanie pojedynczego klawisza bez ENTER
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
