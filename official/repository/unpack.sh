#!/bin/bash
sudo rm -rf /usr/share/LegendaryOS/
sudo mv /tmp/LegendaryOS-Updates/official/repository/LegendaryOS/ /usr/share/
cd /usr/share/LegendaryOS/SCRIPTS/
sudo mkdir legendary
cd legndary
curl -L -o legendary https://github.com/LegendaryOS/legendary/releases/download/0.2/legendary
sudo chmod a+x legendary
sudo chmod a+x /usr/share/LegendaryOS/SCRIPTS/legendaryos-upgrade
