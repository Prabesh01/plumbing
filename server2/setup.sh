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

### pip
# des: pip3 freeze | xargs pip3 uninstall -y

apt install software-properties-common -y
add-apt-repository universe
apt update -y
apt install python3-pip -y

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

