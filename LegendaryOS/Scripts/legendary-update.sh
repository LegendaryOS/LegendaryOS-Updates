#!/bin/bash

# Plik logu
LOGFILE="/tmp/legendary-update.log"

# Kolory i style (256 kolorów + bold)
RESET="\e[0m"
BOLD="\e[1m"

FG_TITLE="\e[38;5;81m"      # jasny cyjan
BG_TITLE="\e[48;5;236m"     # ciemnoszary

FG_HEADER="\e[38;5;226m"    # żółty
BG_HEADER="\e[48;5;238m"    # ciemnoszary

FG_SUCCESS="\e[38;5;34m"    # zielony
FG_WARN="\e[38;5;208m"      # pomarańczowy
FG_ERROR="\e[38;5;196m"     # czerwony
FG_INFO="\e[38;5;39m"       # niebieski

FG_PROMPT="\e[38;5;45m"     # turkusowy

# Animowany pasek postępu - lekko wygładzony i ładniejszy, zachowując Twój wzór
progress_frames=(
"[ <=>         ]"
"[   <=>       ]"
"[     <=>     ]"
"[       <=>   ]"
"[         <=> ]"
"[       <=>   ]"
"[     <=>     ]"
"[   <=>       ]"
"[ <==>        ]"
"[   <==>      ]"
"[     <==>    ]"
"[       <==>  ]"
"[         <==>]"
"[       <==>  ]"
"[     <==>    ]"
"[   <==>      ]"
"[ <===>       ]"
"[   <===>     ]"
"[     <===>   ]"
"[       <===> ]"
"[         <===>]"
"[       <===> ]"
"[     <===>   ]"
"[   <===>     ]"
"[ <====>      ]"
"[   <====>    ]"
"[     <====>  ]"
"[       <====>]"
"[     <====>  ]"
"[   <====>    ]"
"[ <=====>     ]"
"[   <=====>   ]"
"[     <=====> ]"
"[       <=====>]"
"[     <=====> ]"
"[   <=====>   ]"
"[ <======>    ]"
"[   <======>  ]"
"[     <======>]"
"[   <======>  ]"
"[ <=======>   ]"
"[   <=======> ]"
"[     <=======>]"
"[   <=======> ]"
"[ <========>  ]"
"[   <========>]"

)

# Ukryj kursor
hide_cursor() { tput civis; }

# Pokaż kursor
show_cursor() { tput cnorm; }

# Animacja paska postępu, działa podczas działania procesu o PID
show_progress() {
  local pid=$1
  local i=0
  hide_cursor

  while kill -0 "$pid" 2>/dev/null; do
    # Wypisz ramkę z kolorem info
    echo -ne "\r${FG_INFO}${progress_frames[i]}${RESET}"
    i=$(( (i + 1) % ${#progress_frames[@]} ))
    sleep 0.1
  done

  # Wyczyść linię po animacji
  echo -ne "\r$(printf '%*s' ${#progress_frames[0]} '')\r"
  show_cursor
}

# Obsługa przerwania Ctrl+C - sprzątaj i wyjdź
trap_ctrlc() {
  echo -e "\n${FG_ERROR}${BOLD}Przerwano aktualizację!${RESET}"
  show_cursor
  exit 130
}
trap trap_ctrlc INT

# Ramka tytułowa
print_title() {
  local width=48
  echo -e "${BG_TITLE}${FG_TITLE}${BOLD}┌$(printf '─%.0s' $(seq 1 $width))┐${RESET}"
  echo -e "${BG_TITLE}${FG_TITLE}${BOLD}│            LEGENDARY UPDATE SCRIPT            │${RESET}"
  echo -e "${BG_TITLE}${FG_TITLE}${BOLD}└$(printf '─%.0s' $(seq 1 $width))┘${RESET}"
  echo
}

# Wypisywanie statusu z kolorami i ikonami
print_status() {
  local msg="$1"
  local type="$2"
  case "$type" in
    success) echo -e "${FG_SUCCESS}✔ ${msg}${RESET}" ;;
    warn)    echo -e "${FG_WARN}⚠ ${msg}${RESET}" ;;
    error)   echo -e "${FG_ERROR}✖ ${msg}${RESET}" ;;
    info|*)  echo -e "${FG_INFO}➜ ${msg}${RESET}" ;;
  esac
}

# Funkcje aktualizacji:

update_pacman() {
  print_status "Aktualizacja systemu pacman (sudo pacman -Syu)..." info
  sudo pacman -Syu --noconfirm >> "$LOGFILE" 2>&1 &
  local pid=$!
  show_progress "$pid"
  wait "$pid"
  if [[ $? -eq 0 ]]; then
    print_status "System (pacman) zaktualizowany pomyślnie." success
  else
    print_status "Błąd podczas aktualizacji pacmana! Sprawdź $LOGFILE" error
  fi
}

update_flatpak() {
  if ! command -v flatpak &>/dev/null; then
    print_status "flatpak nie jest zainstalowany, pomijam aktualizację flatpaków." warn
    return
  fi

  print_status "Aktualizacja flatpaków..." info
  flatpak update -y >> "$LOGFILE" 2>&1 &
  local pid=$!
  show_progress "$pid"
  wait "$pid"
  if [[ $? -eq 0 ]]; then
    print_status "Flatpaki zaktualizowane pomyślnie." success
  else
    print_status "Błąd podczas aktualizacji flatpaków! Sprawdź $LOGFILE" error
  fi
}

update_firmware() {
  if ! command -v fwupdmgr &>/dev/null; then
    print_status "fwupdmgr nie jest zainstalowany, pomijam aktualizację firmware." warn
    return
  fi

  print_status "Aktualizacja firmware (fwupdmgr)..." info
  sudo fwupdmgr update >> "$LOGFILE" 2>&1 &
  local pid=$!
  show_progress "$pid"
  wait "$pid"
  if [[ $? -eq 0 ]]; then
    print_status "Firmware zaktualizowany pomyślnie." success
  else
    print_status "Błąd podczas aktualizacji firmware! Sprawdź $LOGFILE" error
  fi
}

# Menu po aktualizacji (bez Enter)
post_update_menu() {
  echo
  echo -e "${BG_HEADER}${FG_HEADER}${BOLD} Co chcesz zrobić dalej? ${RESET}"
  echo -e "  (${FG_PROMPT}E${RESET})xit — zamknij skrypt"
  echo -e "  (${FG_PROMPT}T${RESET})ry again — ponów aktualizację"
  echo -e "  (${FG_PROMPT}S${RESET})hutdown — wyłącz komputer"
  echo -e "  (${FG_PROMPT}R${RESET})eboot — uruchom ponownie komputer"
  echo -e "  (${FG_PROMPT}L${RESET})og out — wyloguj się z sesji"
  echo -ne "${FG_PROMPT}Wciśnij literę: ${RESET}"

  # Ustawienia terminala - pojedynczy znak bez Enter
  old_stty_cfg=$(stty -g)
  stty -echo -icanon time 0 min 1
  read -r -n 1 key
  stty "$old_stty_cfg"
  echo

  case "${key,,}" in
    e)
      print_status "Zamykanie skryptu." info
      exit 0
      ;;
    t)
      print_status "Ponawiam aktualizację..." info
      main
      ;;
    s)
      print_status "Wyłączanie komputera..." info
      sudo shutdown now
      ;;
    r)
      print_status "Restartowanie komputera..." info
      sudo reboot
      ;;
    l)
      print_status "Wylogowywanie z sesji..." info
      if command -v gnome-session-quit &>/dev/null; then
        gnome-session-quit --logout --no-prompt
      elif command -v pkill &>/dev/null; then
        pkill -KILL -u "$USER"
      else
        print_status "Nie udało się wylogować - brak znanej metody." warn
      fi
      ;;
    *)
      print_status "Nieznana opcja, zamykam skrypt." error
      exit 1
      ;;
  esac
}

main() {
  clear
  print_title
  echo "START aktualizacji: $(date)" >> "$LOGFILE"
  update_pacman
  update_flatpak
  update_firmware
  echo "WSZYSTKIE aktualizACJE zakończone: $(date)" >> "$LOGFILE"
  print_status "Wszystkie aktualizacje zakończone pomyślnie." success
  post_update_menu
}

main
