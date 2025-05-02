#!/usr/bin/bash

set -e

name="${1:-alex}"

PATH_script=$(realpath "$0")
PATH_wd=$(dirname "$PATH_script")
DEBOOTSTRAP_DIR="$PATH_wd/debootstrap"
CONTAINER_DIR="${PATH_wd}/${name}"  # fs in /tmp has issue with permission

function fn_boot {
    # create the network share using GUI nm-applet for ve-sim
    rm --verbose --force "/var/lib/NetworkManager/dnsmasq-ve-${name}.leases"
    nmcli connection add con-name "syspawn-${name}" type ethernet ifname "ve-${name}" ipv4.method shared
    sleep 3 && nmcli connection up "syspawn-${name}" &
    systemd-nspawn --network-veth --boot --directory="$CONTAINER_DIR"
    nmcli connection delete "syspawn-${name}"
    exit
}


if [ ! -d "$DEBOOTSTRAP_DIR" ]; then
    echo "Debootstrap directory not found. Creating with debootstrap..."
    sudo debootstrap focal "$DEBOOTSTRAP_DIR" http://archive.ubuntu.com/ubuntu
fi


if [ ! -d "$CONTAINER_DIR" ]; then
    echo "Creating new container directory..."
    mkdir -p "$CONTAINER_DIR"
    chmod 755 "$CONTAINER_DIR"
    cp -a "$DEBOOTSTRAP_DIR/"* "$CONTAINER_DIR/"
fi


systemd-nspawn --directory="$CONTAINER_DIR" -- bash -c "
# * SYSTEM
echo "root:groot" | chpasswd
echo 'ub' > /etc/hostname

# ** network
cp /usr/lib/systemd/network/80-container-ve.network /etc/systemd/network/
systemctl enable systemd-networkd
systemctl enable systemd-resolved  # needed since host also uses systemd-resolved

# ** sshd
apt install openssh-server curl -y
mkdir -p ~/.ssh && curl https://github.com/Prabesh01.keys >> ~/.ssh/authorized_keys
"

fn_boot
