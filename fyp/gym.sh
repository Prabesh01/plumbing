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
# npm run seed

sudo -u postgres psql <<EOF
-- Connect
\c gymify

COPY public.users (user_id, user_name, full_name, address, height, current_weight, gender, email, password, phone_number, role, fitness_level, goal_type, card_number, created_at, updated_at, allergies, calorie_goals, profile_image, reset_token, reset_token_expiry, birthdate, otp, otp_expiry, verified, fcm_token) FROM stdin;
1	admin	admin admin	Nepal	175.5	70.2	Male	admin@icp.hoh	$2y$12$l8RkQaKord4CQvyeinQ9oefoC2WOu2KxCssI/EEfVi7OiDd.tNS.S	9834567890	Admin	Athlete	Weight Loss	23C14111	2025-04-04 08:31:35.382	2025-04-15 11:06:47.739	\N	2500.00	https://res.cloudinary.com/dqcdosfch/image/upload/v1744715207/profile_images/fhy76zwrwtq8eax8icew.jpg	\N	\N	2002-03-12 00:00:00	264453	2025-04-21 05:31:44.272	t	\N
2	trainer	trainer trainer	Nepal	175	75	Male	trainer@icp.hoh	$2y$12$l8RkQaKord4CQvyeinQ9oefoC2WOu2KxCssI/EEfVi7OiDd.tNS.S	9801234567	Trainer	Intermediate	Endurance	KOKO	2025-04-04 08:34:26.53	2025-04-21 05:21:51.453	Peanuts	1500.00	https://res.cloudinary.com/dqcdosfch/image/upload/v1744714427/profile_images/jwrtj47wueievnem8g4d.jpg	\N	\N	2002-12-12 00:00:00	\N	\N	t	\N
3	ram	ram	Nepal	175.5	70.2	Male	ram@icp.hoh	$2y$12$l8RkQaKord4CQvyeinQ9oefoC2WOu2KxCssI/EEfVi7OiDd.tNS.S	9812121212	Member	Beginner	Weight Loss	23C14111	2025-04-04 08:31:35.382	2025-04-15 11:06:47.739	\N	1800.00	https://res.cloudinary.com/dqcdosfch/image/upload/v1743880205/profile_images/qbfqylac7jsy53oai2xh.png	\N	\N	2002-03-12 00:00:00	264453	2025-04-21 05:31:44.272	t	\N
\.
EOF

cd ../fe
npm install
npm install vite@latest  --save-dev
