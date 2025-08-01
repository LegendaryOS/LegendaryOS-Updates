const { ipcMain } = require('electron');
const { exec, spawn } = require('child_process');
const util = require('util');
const fs = require('fs');
const { getText } = require('./utils');

const execPromise = util.promisify(exec);

let mainWindow;
let runningProcesses = [];
const lastLaunchTimes = {};

function log(message, level = 'info') {
    const logMessage = `${new Date().toISOString()} - ${level.toUpperCase()} - ${message}\n`;
    fs.appendFileSync('/tmp/legendary-mode.log', logMessage);
}

function setMainWindow(win) {
    mainWindow = win;
}

async function checkAppInstalled(command, appName) {
    try {
        if (command.includes('flatpak')) {
            const flatpakId = command[2];
            const { stdout } = await execPromise('flatpak list --app --columns=application');
            const installedApps = stdout.split('\n').map(app => app.trim()).filter(app => app);
            if (!installedApps.includes(flatpakId)) {
                mainWindow.webContents.executeJavaScript(`alert('${getText('app_not_installed')}');`).catch(e => log(`Error showing alert: ${e}`, 'error'));
                log(`${appName} not installed`, 'error');
                return false;
            }
            return true;
        } else {
            const { stdout } = await execPromise(`which ${command[0]}`);
            if (!stdout) {
                mainWindow.webContents.executeJavaScript(`alert('${getText('app_not_installed')}');`).catch(e => log(`Error showing alert: ${e}`, 'error'));
                log(`${appName} not installed`, 'error');
                return false;
            }
            return true;
        }
    } catch (e) {
        log(`Error checking if ${appName} is installed: ${e}`, 'error');
        mainWindow.webContents.executeJavaScript(`alert('${getText('app_not_installed')}');`).catch(e => log(`Error showing alert: ${e}`, 'error'));
        return false;
    }
}

async function checkInternet() {
    try {
        const { stdout } = await execPromise('nmcli networking connectivity');
        if (stdout.trim() === 'full') return true;
        const { stdout: ping } = await execPromise('ping -c 1 8.8.8.8');
        if (ping) return true;
        return false;
    } catch (e) {
        log(`Error checking internet: ${e}`, 'error');
        return false;
    }
}

async function setFullscreen(appId, appName, retries = 3, delay = 3000) {
    for (let i = 0; i < retries; i++) {
        try {
            await execPromise(`swaymsg '[app_id="${appId}" title=".*${appName}.*"] fullscreen enable'`);
            log(`Set fullscreen for ${appName} (app_id: ${appId})`, 'info');
            return true;
        } catch (err) {
            log(`Attempt ${i + 1} failed to set fullscreen for ${appName}: ${err}`, 'error');
            if (i < retries - 1) {
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }
    log(`Failed to set fullscreen for ${appName} after ${retries} attempts`, 'error');
    return false;
}

ipcMain.handle('launchApp', async (event, appName) => {
    const currentTime = Date.now() / 1000;
    const lastLaunch = lastLaunchTimes[appName] || 0;
    const cooldownSeconds = 60;

    if (currentTime - lastLaunch < cooldownSeconds) {
        const remaining = Math.ceil(cooldownSeconds - (currentTime - lastLaunch));
        mainWindow.webContents.executeJavaScript(`alert('${getText('launch_cooldown', { app: appName, seconds: remaining })}');`).catch(e => log(`Error showing alert: ${e}`, 'error'));
        log(`Launch blocked for ${appName} due to cooldown: ${remaining}s`, 'info');
        return;
    }

    const apps = {
        'retroarch': { command: ['flatpak', 'run', 'org.libretro.RetroArch'], flatpak: true, requiresInternet: false, appId: 'org.libretro.RetroArch' },
        'legendarygames': { command: ['/usr/share/LegendaryOS/Scripts/Legendary-Games/legendary-games'], flatpak: false, requiresInternet: true, appId: 'legendary-games' },
        'ea': { command: ['/usr/share/LegendaryOS/Scripts/Legendary-Mode/ea'], flatpak: false, requiresInternet: true, appId: 'ea' },
        'battlenet': { command: ['/usr/share/LegendaryOS/Scripts/Legendary-Mode/battle.net'], flatpak: false, requiresInternet: true, appId: 'battle.net' },
        'epicgames': { command: ['/usr/share/LegendaryOS/Scripts/Legendary-Mode/epic-games'], flatpak: false, requiresInternet: true, appId: 'epic-games' }
    };

    const app = apps[appName];
    if (!app) {
        log(`Unknown app: ${appName}`, 'error');
        return;
    }

    if (!(await checkAppInstalled(app.command, appName))) {
        return;
    }

    if (app.requiresInternet && !(await checkInternet())) {
        mainWindow.webContents.executeJavaScript(`alert('${getText('no_internet')}');`).catch(e => log(`Error showing alert: ${e}`, 'error'));
        log(`No internet for ${appName}`, 'error');
        return;
    }

    document.getElementById('legendary-menu').classList.add('hidden'); // Hide menu if open
    mainWindow.hide();
    log(`Launching ${appName}`, 'info');

    const proc = spawn(app.command[0], app.command.slice(1), {
        env: { ...process.env, XDG_SESSION_TYPE: 'wayland' },
        detached: true,
        stdio: 'ignore'
    });

    runningProcesses.push([appName, proc]);
    lastLaunchTimes[appName] = currentTime;

    setTimeout(async () => {
        const appId = app.flatpak ? app.command[2] : app.command[0].split('/').pop();
        try {
            await execPromise(`swaymsg '[app_id="${appId}" title=".*${appName}.*"] focus'`);
            log(`Focused ${appName} (app_id: ${appId})`, 'info');
        } catch (err) {
            log(`Error focusing ${appName}: ${err}`, 'error');
        }
        await setFullscreen(appId, appName);
    }, 3000);

    proc.on('close', () => {
        log(`${appName} closed`, 'info');
        runningProcesses = runningProcesses.filter(([name, p]) => p.pid !== proc.pid);
        if (mainWindow) {
            mainWindow.show();
            exec('swaymsg fullscreen enable', (err) => {
                if (err) log(`Error restoring fullscreen for Legendary Mode: ${err}`, 'error');
            });
        }
    });
});

ipcMain.handle('systemAction', async (event, action) => {
    const actions = {
        switchToPlasma: () => {
            log('Switching to Plasma', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            mainWindow.hide();
            exec('systemctl start plasma-kde', (err) => {
                if (err) log(`Error switching to Plasma: ${err}`, 'error');
            });
        },
        shutdown: () => {
            log('Shutting down', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            mainWindow.hide();
            exec('systemctl poweroff', (err) => {
                if (err) log(`Error shutting down: ${err}`, 'error');
            });
        },
        restart: () => {
            log('Restarting', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            mainWindow.hide();
            exec('systemctl reboot', (err) => {
                if (err) log(`Error restarting: ${err}`, 'error');
            });
        },
        sleep: () => {
            log('Suspending', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            mainWindow.hide();
            exec('systemctl suspend', (err) => {
                if (err) log(`Error suspending: ${err}`, 'error');
            });
        },
        restartApps: () => {
            log('Restarting apps', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            ['retroarch', 'legendarygames', 'ea', 'battlenet', 'epicgames'].forEach(app => {
                exec(`pkill -f ${app}`, (err) => {
                    if (err) log(`Error killing ${app}: ${err}`, 'error');
                });
            });
            runningProcesses = [];
            if (mainWindow) {
                mainWindow.show();
                exec('swaymsg fullscreen enable', (err) => {
                    if (err) log(`Error restoring fullscreen: ${err}`, 'error');
                });
            }
        },
        logout: () => {
            log('Logging out', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            mainWindow.hide();
            exec('swaymsg exit', (err) => {
                if (err) log(`Error logging out: ${err}`, 'error');
            });
        },
        restartSway: () => {
            log('Restarting Sway', 'info');
            document.getElementById('legendary-menu').classList.add('hidden');
            mainWindow.hide();
            exec('swaymsg reload', (err) => {
                if (err) log(`Error restarting Sway: ${err}`, 'error');
            });
        }
    };

    if (actions[action]) actions[action]();
});

module.exports = { setMainWindow };
