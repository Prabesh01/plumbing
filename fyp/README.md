- apt install curl nano
- mkdir -p ~/.ssh && curl https://github.com/Prabesh01.keys >> ~/.ssh/authorized_keys

### food

- ./main.sh food --remote=<ip>
- cd /root/food/
- php artisan serve --host=0.0.0.0 --port=8000

## auto

- ./main.sh food --remote=<ip>
- cd /root/auto/ts_autoparts/
- php artisan serve --host=0.0.0.0 --port=8000
- cd /root/auto/ts_autoparts/public/
- python3 -m http.server 5000

## gym

- ./main.sh gym --remote=<ip>
- cd /root/gym/be
- npx prisma migrate deploy && npm start
- cd ../fe
```
IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
sed -i "s|baseURL: '.*'|baseURL: 'http://$IP:8000/api'|" ./src/network/axios.js
```
- npm run dev