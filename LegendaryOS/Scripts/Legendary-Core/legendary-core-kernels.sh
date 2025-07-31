#!/bin/bash
# Script to handle kernel detection and installation

# Function to check if a kernel is installed
check_kernel() {
    local kernel_name=$1
    ls /boot/vmlinuz* | grep -q "$kernel_name"
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

# Function to install tkg kernel
install_tkg() {
    /usr/share/LegendaryOS/Scripts/Legendary-Core/TKG-Kernel/tkg-update
}

# Function to install cacule kernel
install_cacule() {
    if ! command -v yay &> /dev/null; then
        echo "yay is not installed. Please install yay first."
        exit 1
    fi
    yay -S linux-cacule --noconfirm
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

# Function to save kernel choice
save_choice() {
    local kernel=$1
    echo "$kernel" > /etc/legendaryos/kernel-choice
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
            "tkg") install_tkg ;;
            "cacule") install_cacule ;;
            "lts") install_lts ;;
            "hardened") install_hardened ;;
            "arch") install_arch ;;
            *) echo "Unknown kernel: $kernel"; exit 1 ;;
        esac
        ;;
    "save")
        save_choice "$2"
        ;;
    "load")
        load_choice
        ;;
    *) echo "Usage: $0 {check|install|save|load} [kernel]"; exit 1 ;;
esac
