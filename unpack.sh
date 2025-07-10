!#/bin/bash

#uprawnienia sudo
sudo su

#aktualizacja systemu
legendary-update

#usuwanie katalogu /LegendaryOS
rm -rf /usr/share/LegendaryOS

#klonowanie repo
git clone https://github.com/LegendaryOS/LegendaryOS-Updates.git

#wchodzimy do katalogu
cd LegendaryOS-Updates

#aktuakizujemy katalogu

