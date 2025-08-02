const { exec } = require('child_process');
const { app } = require('electron');
const util = require('util');
const execPromise = util.promisify(exec);

document.addEventListener('DOMContentLoaded', async () => {
    const statusDiv = document.getElementById('status');
    const rememberCheckbox = document.getElementById('remember-choice');
    const kernelButtons = document.querySelectorAll('.kernel-btn');

    // Check saved kernel choice
    try {
        const { stdout } = await execPromise('/usr/share/LegendaryOS/Scripts/Legendary-Core/legendary-core-kernels.sh load');
        const savedKernel = stdout.trim();
        if (savedKernel) {
            rememberCheckbox.checked = true;
            statusDiv.textContent = `Saved choice: ${savedKernel}`;
        }
    } catch (error) {
        console.error('Error loading saved choice:', error);
        statusDiv.textContent = `Error loading saved choice: ${error.message}`;
    }

    // Check kernel availability
    for (const btn of kernelButtons) {
        const kernel = btn.dataset.kernel;
        try {
            const { stdout } = await execPromise(`/usr/share/LegendaryOS/Scripts/Legendary-Core/legendary-core-kernels.sh check ${kernel}`);
            if (stdout.trim() === '0') {
                btn.textContent += ' (Installed)';
                btn.disabled = true;
            }
        } catch (error) {
            console.error(`Error checking ${kernel}:`, error);
            statusDiv.textContent = `Error checking ${kernel}: ${error.message}`;
        }
    }

    // Handle kernel selection
    kernelButtons.forEach(btn => {
        btn.addEventListener('click', async () => {
            const kernel = btn.dataset.kernel;
            await selectKernel(kernel);
        });
    });

    async function selectKernel(kernel) {
        if (!confirm(`Install ${kernel} kernel and set it as default?`)) return;
        statusDiv.textContent = `Installing ${kernel} kernel...`;
        try {
            await execPromise(`/usr/share/LegendaryOS/Scripts/Legendary-Core/legendary-core-kernels.sh install ${kernel}`);
            statusDiv.textContent = `${kernel} kernel installed and set as default! Reboot to apply changes.`;
            if (rememberCheckbox.checked) {
                await execPromise(`/usr/share/LegendaryOS/Scripts/Legendary-Core/legendary-core-kernels.sh save ${kernel}`);
                statusDiv.textContent += ' Choice saved.';
            }
            // Launch startplasma-wayland and quit
            await execPromise('startplasma-wayland');
            app.quit();
        } catch (error) {
            statusDiv.textContent = `Error installing ${kernel}: ${error.message}`;
        }
    }
});
