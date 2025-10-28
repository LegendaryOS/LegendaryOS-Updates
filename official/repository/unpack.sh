#!/bin/bash
echo "[INFO] Starting legendaryos upgrade"
echo "[RUN] Deleting old directory"
sudo rm -rf /usr/share/LegendaryOS/
echo "[RUN] Updating directories"
sudo mv /tmp/LegendaryOS-Updates/official/repository/LegendaryOS/ /usr/share/
cd /usr/share/LegendaryOS/SCRIPTS/
sudo mkdir legendary
cd legndary
echo "[INFO] Downloading legendary tool"
curl -L -o legendary https://github.com/LegendaryOS/legendary/releases/download/0.4/legendary-official
sudo mv legendary-official legendary
echo "[RUN] Giving permissions"
sudo chmod a+x legendary
sudo chmod a+x /usr/share/LegendaryOS/SCRIPTS/legendaryos-upgrade
sudo cp -r /usr/share/LegendaryOS/IMAGS/PLYMOUTH/watermark.png /usr/share/plymouth/themes/spinner/
echo "[INFO] Operation complete"
