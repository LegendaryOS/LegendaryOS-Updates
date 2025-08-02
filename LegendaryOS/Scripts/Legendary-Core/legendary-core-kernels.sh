#!/bin/bash
# Script to handle kernel detection, installation, and default setting

# Function to check if a kernel is installed
check_kernel() {
    local kernel_name=$1
    pacman -Q | grep -q "$kernel_name"
    return $?
}

# Function to install xanmod kernel
install_xanmod() {
    if ! command -v yay &> /dev/null; then
        echo "yay is not installed. Please install yay first."
        exit 1
    fi
    yay -S linux-xanmod --noconfirm
}

# Function to install zen kernel
install_zen() {
    sudo pacman -S linux-zen --noconfirm
}

# Function to install lts kernel
install_lts() {
    sudo pacman -S linux-lts --noconfirm
}

# Function to install hardened kernel
install_hardened() {
    sudo pacman -S linux-hardened --noconfirm
}

# Function to install default Arch kernel
install_arch() {
    sudo pacman -S linux --noconfirm
}

# Function to set the default kernel in GRUB
set_default_kernel() {
    local kernel_name=$1
    local kernel_version
    # Get the installed kernel version
    kernel_version=$(pacman -Q | grep "$kernel_name" | awk '{print $2}' | head -1)
    if [ -z "$kernel_version" ]; then
        echo "Error: Could not find version for $kernel_name"
        exit 1
    fi
    # Update GRUB configuration
    local kernel_entry="/boot/vmlinuz-$kernel_name"
    if [ "$kernel_name" = "linux" ]; then
        kernel_entry="/boot/vmlinuz"
    fi
    sudo grubby --set-default "/boot/vmlinuz-${kernel_name}-${kernel_version}"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Function to save kernel choice
save_choice() {
    local kernel=$1
    sudo mkdir -p /etc/legendaryos
    echo "$kernel" | sudo tee /etc/legendaryos/kernel-choice > /dev/null
}

# Function to load saved kernel choice
load_choice() {
    if [ -f /etc/legendaryos/kernel-choice ]; then
        cat /etc/legendaryos/kernel-choice
    else
        echo ""
    fi
}

# Main logic
case $1 in
    "check")
        kernel=$2
        check_kernel "$kernel"
        echo $?
        ;;
    "install")
        kernel=$2
        case $kernel in
            "xanmod") install_xanmod ;;
            "zen") install_zen ;;
            "lts") install_lts ;;
            "hardened") install_hardened ;;
            "arch") install_arch ;;
            *) echo "Unknown kernel: $kernel"; exit 1 ;;
        esac
        set_default_kernel "$kernel"
        ;;
    "save")
        save_choice "$2"
        ;;
    "load")
        load_choice
        ;;
    *) echo "Usage: $0 {check|install|save|load} [kernel]"; exit 1 ;;
esac
