```
./main.sh backup --remote=prabesh
./main.sh restore --remote=prabesh
./main.sh setup --remote=prabesh
```

---

## Commands for manual backup:
rsync -partial --progress --stats --human-readable --human-readable --exclude="proc/" --exclude="snap/" --exclude="kcore" --exclude=".git/" --exclude="node_modules" -e ssh root@prabesh:/ /home/prabesh/vps-backup/prabesh

rsync -partial --progress --stats --human-readable --human-readable --exclude="proc/" --exclude="snap/" --exclude="kcore"  --exclude=".git/" --exclude="node_modules" -e ssh root@stock:/ /home/prabesh/vps-backup/stock

sudo nano /etc/mongod.conf:
```
security:
  authorization: disabled
```

mongodump -d mim -o /root/bla/mongo
mongodump -d lb -o /root/bla/mongo

crontab -l > crontab.txt
