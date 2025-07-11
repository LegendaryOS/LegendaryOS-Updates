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

mv /LegendaryOS/Scripts/Kernel-Updater/etc/systemd/system/update-tkg-kernel.service /etc/systemd/system/
mv LegendaryOS/Scripts/Kernel-Updater/etc/systemd/system/update-tkg-kernel.timer /etc/systemd/system/

mv /LegendaryOS/Scripts/update-tkg-kernel.sh /usr/bin/
chmod a+x /usr/bin/update-tkg-kernel.sh

#aktuakuzacja <===> .release
chmod a+x /home/$(whoami)/LegendaryOS-Updates/Update-Release.sh
/home/$(whoami)/LegendaryOS-Updates/Update-Release.sh

#aktualizacja <===> /usr/share/LegendaryOS/
mv /home/$(whoami)/LegendaryOS-Updates/LegendaryOS/ /usr/share/
