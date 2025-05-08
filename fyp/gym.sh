set -x
set -e

export PS4='\033[4m\033[1;33m[EXEC]\033[0m \033[0m'

log_dir="/var/log/gym/"
mkdir -p "${log_dir}" || true

apt install git -y

### nodejs
sudo apt remove --purge nodejs npm -y
curl -sL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
apt install nodejs -y
npm install -g npm@latest

## postgresql
apt install postgresql -y
systemctl enable --now postgresql
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS gymify;
CREATE DATABASE gymify;
DROP ROLE IF EXISTS gymify;
CREATE USER gymify WITH PASSWORD 'password';

-- Connect
\c gymify

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE gymify TO gymify;
CREATE SCHEMA gymify_schema;
GRANT ALL PRIVILEGES ON SCHEMA gymify_schema TO gymify;
EOF


## get project
cd /root/
mv gym gym.bk
git clone https://github.com/AashishRauniyar/fyp-gymify gym
cp -r gym.bk/. gym/
rm -rf gym.bk/

cd gym/be/
npm install
npm install prisma
npx prisma migrate deploy
npm run seed

cd ../fe
npm install
npm install vite@latest  --save-dev
