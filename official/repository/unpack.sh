#!/bin/bash
echo "[INFO] Starting legendaryos upgrade"
echo "[RUN] Deleting old directory"
sudo rm -rf /usr/share/LegendaryOS/
echo "[RUN] Updating directories"
sudo mv /tmp/LegendaryOS-Updates/official/repository/LegendaryOS/ /usr/share/
cd /usr/share/LegendaryOS/SCRIPTS/
sudo mkdir legendary
sudo mkdir terminal-legend
cd legndary
echo "[INFO] Downloading legendary tool"
curl -L -o legendary https://github.com/LegendaryOS/legendary/releases/download/0.4/legendary-official
cd ..
cd terminal-legend
curl -L -o tl-fronted https://github.com/LegendaryOS/Terminal-Legend/releases/download/0.1/tl-fronted
curl -L -o tl-backend https://github.com/LegendaryOS/Terminal-Legend/releases/download/0.1/tl-backend
echo "[RUN] Giving permissions"
sudo chmod a+x /usr/share/LegendaryOS/SCRIPTS/legendary/legendary
sudo chmod a+x /usr/share/LegendaryOS/SCRIPTS/terminal-legend/tl-fronted
sudo chmod a+x /usr/share/LegendaryOS/SCRIPTS/terminal-legend/tl-backend
sudo chmod a+x /usr/share/LegendaryOS/SCRIPTS/legendaryos-upgrade
sudo cp -r /usr/share/LegendaryOS/IMAGS/PLYMOUTH/watermark.png /usr/share/plymouth/themes/spinner/
echo "[INFO] Operation complete"
