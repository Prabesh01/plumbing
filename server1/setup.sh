set -x
set -e

export PS4='\033[4m\033[1;33m[EXEC]\033[0m \033[0m'

apt update -y
apt upgrade -y

apt remove --purge snapd -yy
apt-mark hold snapd
apt autoremove -y
rm -rf /root/snap

#########################################################################################

## rutu
# des: rm -rf rutu

apt install git -y

mv rutu rutu.bk
git clone https://gitlab.com/Prabesh01/rutu.git
cp -r rutu.bk/. rutu/
rm -rf /root/rutu.bk

mkdir -p /var/log/rutu/

### pip
# des: pip3 freeze | xargs pip3 uninstall -y

# apt install software-properties-common -y
# add-apt-repository universe
# apt update -y
apt install python3-pip -y

pip3 install discord.py pytz python-dotenv facebook-scraper nepali-datetime pymongo discord-webhook topggpy pillow nepali-unicode-converter wrapt-timeout-decorator asgiref openai langdetect
# scirpts/play.py
pip3 install audioread pytube
# scirpts/backup.py
apt install zip -y
# web
pip3 install fastapi jinja2 uvicorn

### out/ files
python3 /root/rutu/scripts/miti.py
python3 /root/rutu/scripts/cal.py
python3 /root/rutu/scripts/xutti.py

### mongod

apt-get install gnupg curl -y

# curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
#     gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
#    --dearmor
# echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-4.4.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

apt-get update -y
apt install -y mongodb-org
systemctl enable --now mongod

for d in $(ls /root/export/mongo); do mongorestore -d $d /root/export/mongo/$d; done
rm -rf /root/export/mongo

mongo --eval 'db.getSiblingDB("admin").createUser({user: "Routiney", pwd: "sdhf63br78fn@329", roles: ["root"]})'

#### nginx

systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1
apt remove apache2 -y
apt install nginx -y
systemctl enable --now nginx

cp /root/rutu/web/cw.nginx /etc/nginx/sites-available/ronb.conf
ln -s /etc/nginx/sites-available/ronb.conf /etc/nginx/sites-enabled/ronb.conf
nginx -t
nginx -s reload

### start web
nohup env PYTHONPATH=/root/rutu/web/ uvicorn main:app --host 0.0.0.0 --port 8000 > /var/log/rutu/web.log 2>&1 &

### run bot.py and server.bot.py
nohup python3 -u ~/rutu/bot.py >  /var/log/rutu/bot.log 2>&1 &
nohup python3 -u ~/rutu/server.bot.py 1 >  /var/log/rutu/server.bot.log 2>&1 &

#########################################################################################

## radio

apt install ffmpeg -y
chmod +x /root/radio/radio.sh
nohup /root/radio/radio.sh &

#########################################################################################

## netmask

pip3 install netmask

> /etc/systemd/system/netmask.service cat <<<"
[Unit]
Description=Netmask Server

[Service]
ExecStart=/usr/bin/python3 -c \"from netmask.server.main import NetmaskServer; server = NetmaskServer('0', False).start('0.0.0.0', '-', 1024)\"
Restart=always
User=root

[Install]
WantedBy=multi-user.target
"
systemctl daemon-reload
systemctl enable --now netmask

#########################################################################################

## squid

apt install squid -y
apt install apache2-utils -y
htpasswd -cb /etc/squid/passwords squid squidpass

sed  -i '/include \/etc\/squid\/conf.d\/\*/a \
auth_param basic program \/usr\/lib\/squid3\/basic_ncsa_auth \/etc\/squid\/passwords\
auth_param basic realm proxy\
acl authenticated proxy_auth REQUIRED\
http_access allow authenticated' /etc/squid/squid.conf

systemctl restart squid.service

#########################################################################################

## mst

curl https://raw.githubusercontent.com/Prabesh01/icpmap/refs/heads/main/mst-automation/discord_tg_notification.py -o /root/mst/mst.py

#########################################################################################

## k

apt install php php-fpm -y
systemctl enable --now php7.4-fpm

systemctl stop apache2 > /dev/null 2>&1
systemctl disable apache2 > /dev/null 2>&1
apt remove apache2 -y

cp /var/www/mamata/nginx.conf /etc/nginx/sites-available/mamata.conf
ln -s /etc/nginx/sites-available/mamata.conf /etc/nginx/sites-enabled/mamata.conf
nginx -t
nginx -s reload

#########################################################################################

## cookfood

git clone https://github.com/Prabesh01/cookfood.git
pip3 install flask gunicorn

cp /root/cookfood/cookfood.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/cookfood.conf /etc/nginx/sites-enabled/cookfood.conf
nginx -t
nginx -s reload

cp /root/cookfood/cookfood.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now cookfood.service

#########################################################################################

## crontab restore

crontab /root/export/crontab.txt
rm -rf /root/export/

