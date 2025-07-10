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
mv /LegendaryOS/Scripts/legendary-update.sh /usr/bin/
chmod a+x /usr/bin/legendary-update.sh

mv /LegendaryOS/Scripts/Kernel-Updater/etc/systemd/system/ /etc/systemd/system
