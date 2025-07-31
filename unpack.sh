!#/bin/bash

#uprawnienia sudo
sudo su

#aktualizacja systemu
legendary-update

#usuwanie starego katalogu /LegendaryOS
rm -rf /usr/share/LegendaryOS

#klonowanie repo
git clone https://github.com/LegendaryOS/LegendaryOS-Updates.git

#wchodzimy do katalogu
cd /tmp/LegendaryOS-Updates

#aktuakizujemy katalogu
mv /tmp/LegendaryOS-Updates/Config-Files/legendary-update /bin/
chmod a+x //bin/legendary-update

#Przenosimy LegendaryOS do /usr/share
mv /home/$(whoami)/LegendaryOS-Updates/LegendaryOS/ /usr/share/

#aktualizacja legendary mode
cd /usr/share/LegendaryOS/Scripts/Legendary-Mode/electron-app/
npm install
