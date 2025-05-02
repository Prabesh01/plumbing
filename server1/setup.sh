set -v

apt update -y
apt upgrade -y

## rutu

apt install git nano python3-pip -y
git clone https://gitlab.com/Prabesh01/rutu.git

### rutu utils

#### sth

#### mongod

apt-get install gnupg curl -y

curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

apt-get update -y
apt-get install -y mongodb-org
systemctl enable --now mongod

