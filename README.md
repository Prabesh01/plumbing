## ./spawn.sh

- creates systemd container with ubuntu focal (changable to any distro). `systemd-nspawn` and `debootstrap` required!
- no docker bs. yay!
- can simulate my vps for testing scripts before running scripts on actual vps.
- working tested on archlinux and ubuntu.
- creates network conenctivity between host and container: `NetworkManager` and `nmcli` required!
- adds my hardcoaded public key into root's .ssh/ dir so that i can directly ssh into it

all this from ~50 lines of code!