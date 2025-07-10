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
