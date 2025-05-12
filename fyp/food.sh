set -x
set -e

export PS4='\033[4m\033[1;33m[EXEC]\033[0m \033[0m'

log_dir="/var/log/food/"
mkdir -p "${log_dir}" || true

apt install git -y

### php
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update -y
apt install unzip php8.2 php8.2-{cli,mysql,xml,dom,curl,mbstring,intl} -y

sudo apt-add-repository universe -y
apt update -y
apt install php8.2-zip -y

### nodejs
curl -sL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
apt install nodejs -y

## mysql

apt install mysql-server -y
systemctl enable --now mysql.service

# mysql setup
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';"
mysql -e "DROP DATABASE  laravel;" || true
mysql -e "CREATE DATABASE laravel;"

## get project
cd /root/
mv food food.bk
git clone https://github.com/SmritiGrg/FYP-FoodiesArchive.git food
cp -r food.bk/. food/
rm -rf /root/food.bk

## composer
cd food
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"

## project setup
echo "yes" | COMPOSER_ALLOW_SUPERUSER=1 php composer.phar install
npm install
npm run build
php artisan migrate
php artisan key:generate

# pass: testP@22
mysql -e "INSERT INTO laravel.users (full_name,username,email,password,role,created_at,updated_at) VALUES ('admin','admin','admin@icp.hoh','\$2y\$12\$l8RkQaKord4CQvyeinQ9oefoC2WOu2KxCssI/EEfVi7OiDd.tNS.S','admin','2025-05-08 19:03:11','2025-05-08 19:03:11');"
mysql -e "INSERT INTO laravel.users (full_name,username,email,password,role,created_at,updated_at) VALUES ('ram','prabesh','ram@icp.hoh','\$2y\$12\$l8RkQaKord4CQvyeinQ9oefoC2WOu2KxCssI/EEfVi7OiDd.tNS.S','general','2025-05-08 19:03:11','2025-05-08 19:03:11');"
