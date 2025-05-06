set -v
set -e

apt update -y
apt upgrade -y

apt remove --purge snapd -yy
apt-mark hold snapd
apt autoremove -y
rm -rf /root/snap

#########################################################################################

## hoh challenges
# des: rm -rf hoh-challenges

useradd ctf_sandbox_user
chsh ctf_sandbox_user -s /bin/no-login

### pip
# des: pip3 freeze | xargs pip3 uninstall -y

apt install software-properties-common -y
add-apt-repository universe
apt update -y
apt install python3-pip python3-venv libpcap-dev nodejs git -y

#### nginx

systemctl stop apache2 || true
systemctl disable apache2 || true
apt remove apache2 -y || true
apt install nginx -y
systemctl enable --now nginx

cp /root/rutu/web/cw.nginx /etc/nginx/sites-available/ronb.conf
ln -s /etc/nginx/sites-available/ronb.conf /etc/nginx/sites-enabled/ronb.conf
nginx -t
nginx -s reload

#### php
apt install php php-fpm -y
systemctl enable --now php7.4-fpm

systemctl stop apache2 || true
systemctl disable apache2 || true
apt remove apache2 -y || true


### challenges

declare -A chroot_commands=(
    ["abay"]="/app/.venv/bin/python3 /app/main.py"
    ["displaced"]="/usr/bin/node /app/main.js"
    ["gtavi"]="/app/.venv/bin/python3 /app/main.py"
    ["maltrail"]="/.venv/bin/python3 /server.py"
    ["probably"]="/app/.venv/bin/python3 /app/main.py"
    ["templated"]="/app/.venv/bin/python3 /app/main.py"
)
for challenge in "${!chroot_commands[@]}"; do
    cd "/root/hoh-challenges/${challenge}-source"
    ./"${challenge}.sh"
    nohup chroot --userspec=ctf_sandbox_user "/root/hoh-challenges/${challenge}-source/${challenge}" ${chroot_commands[$challenge]} &
done

# non chroot challenges
nohup python3 /root/hoh-challenges/sanitize/app.py &
nohup python3 /root/hoh-challenges/tickethub/main.py &

# idiota challenge - my fav
nohup python3 /root/hoh-challenges/idiota/main.py &
# nginx conf
cp /root/hoh-challenges/idiota//idiota.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/idiota.conf /etc/nginx/sites-enabled/idiota.conf
nginx -t
nginx -s reload

# php challenges
mkdir -p /var/www/html/
# copy inlane, php_is_tricky and magic_has to /var/www/html/
cp -r /root/hoh-challenges/inlane/* /var/www/html/
cp -r /root/hoh-challenges/php_is_tricky/ /var/www/html/
cp -r /root/hoh-challenges/magic_hash/ /var/www/html/login

