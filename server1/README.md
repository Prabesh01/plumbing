# ./main.sh

__personalized for my server #1 which hosts few stuffs__

- Commands:
```
./main.sh backup --remote=ip_of_container_or_vps
./main.sh restore --remote=ip_of_container_or_vps
./main.sh setup --remote=ip_of_container_or_vps
```

- Fisrt, run backup command to backup required data from vps.
- Then you can format/rebuild/reset the vps.
- Backup keeps the data in backups_<date> dir. Rename it to backups dir as restore function looks for this dir.

once the vps is rebuld/reset,

- apt install openssh-server curl nano rsync
- mkdir -p ~/.ssh && curl https://github.com/Prabesh01.keys >> ~/.ssh/authorized_keys
- now run restore command to restore earlier backedup files.
- finally run setup command and all set.
