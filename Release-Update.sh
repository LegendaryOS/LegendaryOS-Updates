#!/bin/bash

# Ścieżki
CONFIG_FILE="/etc/xdg/kcm-about-distrorc"
USER_HOME="/home/$(whoami)"
SRC_DIR="$USER_HOME/LegendaryOS-Updates"
DST_DIR="$USER_HOME/.LegendaryOS"

# Sprawdź, czy plik konfiguracyjny istnieje
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Plik konfiguracyjny $CONFIG_FILE nie istnieje."
  exit 1
fi

# Pobierz wartość variant z pliku (zakładając format: variant=...)
VARIANT=$(grep -E '^variant=' "$CONFIG_FILE" | cut -d'=' -f2- | tr -d ' ')

# Działanie w zależności od wariantu
case "$VARIANT" in
  "Official Edition")
    SRC_FILE="$SRC_DIR/.release-official"
    ;;
  "Blue Edition")
    SRC_FILE="$SRC_DIR/.release-blue"
    ;;
  *)
    echo "Nieznany wariant: $VARIANT"
    exit 2
    ;;
esac

# Sprawdź, czy źródłowy plik istnieje
if [[ ! -f "$SRC_FILE" ]]; then
  echo "Plik źródłowy $SRC_FILE nie istnieje."
  exit 3
fi

# Utwórz katalog docelowy, jeśli nie istnieje
mkdir -p "$DST_DIR"

# Kopiuj i zmień nazwę pliku
cp "$SRC_FILE" "$DST_DIR/.release"
echo "Plik $SRC_FILE został skopiowany do $DST_DIR/.release"

# Jeżeli Blue Edition, wykonaj dodatkowe komendy npm
if [[ "$VARIANT" == "Blue Edition" ]]; then
  echo "#aktualizacja - instalacja npm dla Blue Edition"
  
  echo "Instalacja w /usr/share/LegendaryOS/Legendary-Apps/Nova-Play/"
  cd /usr/share/LegendaryOS/Legendary-Apps/Nova-Play/ || { echo "Nie można wejść do katalogu Nova-Play"; exit 4; }
  npm install || { echo "npm install nie powiódł się w Nova-Play"; exit 5; }
  
  # Powtórzone npm install w tym samym katalogu (jeśli ma być 2 razy)
  npm install || { echo "npm install nie powiódł się w Nova-Play (drugi raz)"; exit 6; }
  
  echo "Instalacja w /usr/share/LegendaryOS/Legendary-Apps/Sava-Browser/fronted/"
  cd /usr/share/LegendaryOS/Legendary-Apps/Sava-Browser/fronted/ || { echo "Nie można wejść do katalogu Sava-Browser/frontend"; exit 7; }
  npm install || { echo "npm install nie powiódł się w Sava-Browser/fronted"; exit 8; }
  
  echo "Aktualizacja aplikacji legendaryos zakończona."
fi
