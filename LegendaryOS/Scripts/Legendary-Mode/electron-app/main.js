const { app, BrowserWindow, ipcMain } = require('electron');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { setMainWindow } = require('./launchers');
const { setWindows } = require('./settings');
const { setupLanguage, getText } = require('./utils');

let mainWindow, settingsWindow;

function log(message, level = 'info') {
    const logMessage = `${new Date().toISOString()} - ${level.toUpperCase()} - ${message}\n`;
    fs.appendFileSync('/tmp/legendary-mode.log', logMessage);
}

function createWindow() {
    mainWindow = new BrowserWindow({
        fullscreen: true,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js')
        },
        backgroundColor: '#000000'
    });

    mainWindow.loadFile('index.html').catch(e => log(`Error loading index.html: ${e}`, 'error'));

    mainWindow.on('closed', () => {
        mainWindow = null;
        if (settingsWindow) settingsWindow.close();
    });

        setMainWindow(mainWindow);
        setWindows(mainWindow, settingsWindow);

        mainWindow.webContents.on('did-finish-load', () => {
            mainWindow.webContents.executeJavaScript(`
            document.getElementById('title').innerText = '${getText('title')}';
            document.getElementById('settings-btn').innerText = '${getText('settings')}';
            document.getElementById('legendary-menu-btn').innerText = '${getText('legendary_menu')}';
            gsap.from('.launcher-btn', { duration: 1, y: 50, opacity: 0, stagger: 0.1 });
            `).catch(e => log(`Error executing JavaScript in main window: ${e}`, 'error'));
        });

        require('child_process').exec('swaymsg fullscreen enable', (err) => {
            if (err) log(`Error setting fullscreen: ${err}`, 'error');
        });
}

function createSettingsWindow() {
    if (!mainWindow) return;
    mainWindow.hide();

    settingsWindow = new BrowserWindow({
        fullscreen: true, // Changed from width/height to fullscreen
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js')
        },
        backgroundColor: '#000000',
        parent: mainWindow,
        modal: true
    });

    settingsWindow.loadFile('settings.html').catch(e => log(`Error loading settings.html: ${e}`, 'error'));

    settingsWindow.on('closed', () => {
        settingsWindow = null;
        if (mainWindow) {
            mainWindow.show();
            require('child_process').exec('swaymsg fullscreen enable', (err) => {
                if (err) log(`Error restoring fullscreen for main window: ${err}`, 'error');
            });
        }
    });

    setWindows(mainWindow, settingsWindow);

    settingsWindow.webContents.on('did-finish-load', () => {
        settingsWindow.webContents.executeJavaScript(`
        document.getElementById('settings-title').innerText = '${getText('settings')}';
        document.getElementById('language-select').value = '${setupLanguage()}';
        document.getElementById('audio-title').innerText = '${getText('audio')}';
        document.getElementById('display-title').innerText = '${getText('display')}';
        document.getElementById('network-title').innerText = '${getText('network')}';
        document.getElementById('power-title').innerText = '${getText('power')}';
        document.getElementById('general-title').innerText = '${getText('general')}';
        document.getElementById('wifi-title').innerText = '${getText('wifi_settings')}';
        document.getElementById('bluetooth-title').innerText = '${getText('bluetooth')}';
        document.getElementById('close-btn').innerText = '${getText('close')}';
        gsap.from('.setting-panel', { duration: 0.8, y: 50, opacity: 0, stagger: 0.1 });
        `).catch(e => log(`Error executing JavaScript in settings window: ${e}`, 'error'));

        require('child_process').exec('swaymsg fullscreen enable', (err) => {
            if (err) log(`Error setting fullscreen for settings window: ${err}`, 'error');
        });
    });
}

app.whenReady().then(() => {
    // Enable Wayland and disable hardware acceleration to mitigate GL errors
    app.commandLine.appendSwitch('enable-features', 'UseOzonePlatform');
    app.commandLine.appendSwitch('ozone-platform', 'wayland');
    app.commandLine.appendSwitch('disable-gpu'); // Optional: disable if GL errors persist

    setupLanguage();
    createWindow();
    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
}).catch(e => log(`Error during app startup: ${e}`, 'error'));

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('launchSettings', async () => {
    log('Launching settings', 'info');
    if (!settingsWindow && mainWindow) createSettingsWindow();
});

ipcMain.handle('closeSettings', async () => {
    log('Closing settings', 'info');
    if (settingsWindow) {
        settingsWindow.close();
        if (mainWindow) {
            mainWindow.show();
            require('child_process').exec('swaymsg fullscreen enable', (err) => {
                if (err) log(`Error restoring fullscreen for main window: ${err}`, 'error');
            });
        }
    }
});

ipcMain.handle('initSettings', async () => {
    log('Initializing settings', 'info');
    if (settingsWindow) {
        settingsWindow.webContents.executeJavaScript(`
        document.querySelectorAll('button[data-action*="Volume"]').forEach(btn => {
            if (btn.innerText.includes('Increase')) btn.innerText = '${getText('increase_volume')}';
            else if (btn.innerText.includes('Decrease')) btn.innerText = '${getText('decrease_volume')}';
            else if (btn.innerText.includes('Toggle')) btn.innerText = '${getText('toggle_mute')}';
        });
        document.querySelectorAll('button[data-action*="Brightness"]').forEach(btn => {
            if (btn.innerText.includes('Increase')) btn.innerText = '${getText('increase_brightness')}';
            else if (btn.innerText.includes('Decrease')) btn.innerText = '${getText('decrease_brightness')}';
            else if (btn.innerText.includes('Toggle')) btn.innerText = '${getText('toggle_theme')}';
        });
        document.querySelectorAll('button[data-action*="Wifi"]').forEach(btn => {
            if (btn.innerText.includes('Wi-Fi Settings')) btn.innerText = '${getText('wifi_settings')}';
            else if (btn.innerText.includes('Toggle')) btn.innerText = '${getText('toggle_wifi')}';
            else if (btn.innerText.includes('Connect')) btn.innerText = '${getText('connect')}';
        });
        document.querySelectorAll('button[data-action*="Bluetooth"]').forEach(btn => {
            if (btn.innerText.includes('Bluetooth')) btn.innerText = '${getText('bluetooth')}';
            else if (btn.innerText.includes('Scan')) btn.innerText = '${getText('scan')}';
            else if (btn.innerText.includes('Pair')) btn.innerText = '${getText('pair')}';
        });
        document.querySelectorAll('button[data-action*="power"]').forEach(btn => {
            if (btn.innerText.includes('Power Saving')) btn.innerText = '${getText('power_saving')}';
            else if (btn.innerText.includes('Balanced')) btn.innerText = '${getText('balanced')}';
            else if (btn.innerText.includes('Performance')) btn.innerText = '${getText('performance')}';
        });
        document.getElementById('close-btn').innerText = '${getText('close')}';
        `).catch(e => log(`Error initializing settings: ${e}`, 'error'));
    }
});
