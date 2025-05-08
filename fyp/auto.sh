set -x
set -e

export PS4='\033[4m\033[1;33m[EXEC]\033[0m \033[0m'

log_dir="/var/log/auto/"
mkdir -p "${log_dir}" || true

apt install git -y

### php
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update -y
apt install unzip php8.2 php8.2-{cli,mysql,xml,dom,curl,mbstring,intl} -y

apt-add-repository universe -y
apt update -y
apt install php8.2-zip -y

### nodejs
sudo apt remove --purge nodejs npm -y
curl -sL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
apt install nodejs -y
npm install -g npm@latest

## mysql

apt install mysql-server -y
systemctl enable --now mysql.service

# mysql setup
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
mysql -e "DROP DATABASE  ts_autoparts;" || true
mysql -e "CREATE DATABASE ts_autoparts;"

## get project
cd /root/
mv auto auto.bk
git clone -b master --single-branch https://github.com/KripaKadel/TS-Autoparts.git auto
cp -r auto.bk/. auto/
rm -rf /root/auto.bk

## composer
cd auto/ts_autoparts
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"

## project setup

npm install laravel-vite-plugin --save-dev
npm install vite@latest  --save-dev

echo "yes" | COMPOSER_ALLOW_SUPERUSER=1 php composer.phar install
php artisan migrate
php artisan key:generate
