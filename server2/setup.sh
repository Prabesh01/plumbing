set -x
set -e

export PS4='\033[4m\033[1;33m[EXEC]\033[0m \033[0m'

apt update -y
apt upgrade -y

apt remove --purge snapd -yy
apt-mark hold snapd
apt autoremove -y
rm -rf /root/snap

log_dir="/root/botlogs/"
mkdir "${log_dir}" || true

#########################################################################################

## hoh challenges
# des: rm -rf hoh-challenges

useradd ctf_sandbox_user || true
chsh ctf_sandbox_user -s /bin/no-login
apt install libpcap-dev nodejs git -y

### pip
# des: pip3 freeze | xargs pip3 uninstall -y

# apt install software-properties-common -y
# add-apt-repository universe
# apt update -y
apt install python3-pip python3-venv -y

pip install flask Flask-SQLAlchemy

#### nginx

systemctl stop apache2 || true
systemctl disable apache2 || true
apt remove apache2 -y || true
apt install nginx -y
systemctl enable --now nginx

#### php
apt install php php-fpm -y
installed_php=$(systemctl list-unit-files 'php*-fpm.service' | grep -oP 'php\d+\.\d+-fpm')
systemctl enable --now "${installed_php}"

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

> /etc/nginx/sites-available/default cat <<<"server {
	listen 80 default_server;
	listen [::]:80 default_server;

	root /var/www/html;
	index index.php index.html;

	server_name _;

	location / {
		try_files \$uri \$uri/ =404;
	}

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/run/php/php-fpm.sock;
		include      fastcgi.conf;
	}
}
"

nginx -s reload

#########################################################################################

## discord-vc-attendance: icpbot/hoh.cote.ws

cd /root/
mv discord-vc-attendance discord-vc-attendance.bk
git clone https://github.com/Prabesh01/discord-vc-attendance.git
cp -r discord-vc-attendance.bk/. discord-vc-attendance/
rm -rf /root/discord-vc-attendance.bk

### pip
pip3 install discord.py pytz requests filelock python-dotenv

### run
nohup python3 -u /root/discord-vc-attendance/bot.py > "${log_dir}"/hoh-bot.log 2>&1 &
nohup python3 -u /root/discord-vc-attendance/web/app.py > "${log_dir}/hoh-web.log" 2>&1 &

## nginx
cp /root/discord-vc-attendance/web/nginx.conf /etc/nginx/sites-available/hoh.conf
ln -s /etc/nginx/sites-available/hoh.conf /etc/nginx/sites-enabled/hoh.conf
nginx -s reload

#########################################################################################

## ctfd

curl https://gist.githubusercontent.com/Prabesh01/57643d03db9126659870153e893d37c5/raw/6cf9f199d2c456408f344f6ef91d5e65acdfe09a/ctfd.py -o /root/ctfd.py

#########################################################################################

## conan

cd /root/
mv ctf-discord-bot ctf-discord-bot.bk
git clone -b multiple-server-support --single-branch https://github.com/Prabesh01/ctf-discord-bot.git
cp -r ctf-discord-bot.bk/. ctf-discord-bot/
rm -rf /root/ctf-discord-bot.bk

### pip
pip3 install django pillow

### run
nohup python3 -u /root/ctf-discord-bot/ctfdash/manage.py runserver 5050 > "${log_dir}/conan-web.log" 2>&1 &
nohup python3 -u /root/ctf-discord-bot/bot.py > "${log_dir}/conan-bot.log" 2>&1 &


### nginx
cp /root/ctf-discord-bot/nginx.conf /etc/nginx/sites-available/conan.conf
ln -s /etc/nginx/sites-available/conan.conf /etc/nginx/sites-enabled/conan.conf
nginx -s reload

#########################################################################################

## certbot
apt install certbot python3-certbot-nginx -y
certbot --nginx -d conan.cote.ws --non-interactive --agree-tos -m prabesh@cote.ws
certbot --nginx -d hoh.cote.ws --non-interactive --agree-tos -m prabesh@cote.ws
certbot --nginx -d icpmail.cote.ws --non-interactive --agree-tos -m prabesh@cote.ws

sudo systemctl enable --now  certbot.timer

#########################################################################################

## crontab restore

crontab /root/export/crontab.txt
rm -rf /root/export/

