## A restic-based backup system on a family PC

The following is based on an installation on FreeBSD 14.  It is almost certain that the scripts will have to be tweaked to run on another distribution, as will the include and exclude files.  For now, treat restic configuration and script files as readonly on non-FreeBSD systems.  The README.md file should be maintained, though.

 On non-FreeBSD systems, I've tended to use `/root/.config/restic/` as the equivalent of `/usr/local/etc` and `/usr/local/bin` as the equivalent of `/usr/local/scripts`. 

### Installation 
1. As root, create the necessary subdirectories:

    ```bash
    sudo -s
    mkdir -p /usr/local/etc/restic-backup /usr/local/etc/resticctl /usr/local/scripts /usr/local/var/backups /var/log/restic
    ```
2. Install `restic`

    ```bash
    sudo pkg install restic
    ```
3. Install scripts, configuration files and service keys:
   - `/usr/local/etc/restic-backup/{retic-backup.conf,include-in-backup,exclude-from-backup,home-data-storage-xxxysys.json}`
   - `/usr/local/etc/resticctl/{reticctl.conf,home-data-storage-xxxysys.json}`
   - `/usr/local/scripts/{restic-backup.sh,resticctl.sh[,postgres-backup.sh]}`
4. Set permissions so that only root may access files:

    ```bash
    chown -R root:wheel /usr/local/etc/restic*
    chown -R root:wheel /usr/local/scripts
    chmod 750 /usr/local/etc/{resticctl,restic-backup}
    chmod 600 /usr/local/etc/{resticctl,restic-backup}/*
    chmod 750 /usr/local/scripts/*
    chmod 777 /usr/local/var/backups  #  other users should be able store files in this catch-all backups directory (eg postgres)
    ```
5. Set up root's crontab by running `sudo crontab -e` and entering:

    ```
    # Run restic to backup data to GCS every day at 04:05am; also 2 minutes after rebooting.
    05 04 * * * /usr/local/scripts/restic-backup.sh >>/var/log/restic/backup.log
    @reboot     sleep 120 && /usr/local/scripts/restic-backup.sh >>/var/log/restic/backup.log
    ```
6. Set up log rotation:

    ```bash
    # FreeBSD: /usr/local/etc/newsyslog.conf.d/restic-backup-newsyslog.conf
    /var/log/restic/backup.log   root:wheel  644    10  1024  *  -
    
    # ArchLinux: /etc/logrotate.d/restic-backup
    /var/log/restic/backup.log {
    create 0644 root wheel
    rotate 10
    size 1024k
    notifempty
    missingok
    copytruncate
    }
    ```
    
7. Initialise the repository.  **Remember to confirm that both `resticctl.conf` and `restic-backup.conf` have been changed to include the current value of `hostname -s` in the bucket path.

    ```bash
    resticctl.sh init
    ```

### Useful  info

Online docs available [here](https://restic.readthedocs.io/en/stable/010_introduction.html)

GCS cloud storage is owned by ldffrench@gmail.com (credentials in BitWarden).  Backups live in bucket *french-family-restic-backups*.  Each host has its own 'directory' (eg ganymede, io, jupiter)

Progress is logged to `/var/log/restic/backup.log`

##### Used storage space

Working out how much space is being used on the destination is not intuitive.  The command to uses is **stats** but the default mode (*restore-size*) is to respond with how much space would be required to restore the snapshot named in the command.  If a snapshot name is not given then it sums the size of all restoring all snapshots in sequence.  To see how much space is being consumed on the remote use mode *raw-data*.

```bash
sudo /usr/local/scripts/resticctl.sh stats --mode=raw-data
```
For example, if I look at how much space is used by jupiter using `gsutil du -h -s -a gs://french-family-restic-backups/jupiter`.  But if I run `sudo /usr/local/scripts/resticctl.sh stats` I get 11TB!!!.  `--mode=raw-data` agrees with `gsutil du ...` 

##### List snapshots:

```bash
sudo /usr/local/scripts/resticctl.sh snapshots
``` 

##### Check metadata integrity

```bash
sudo /usr/local/scripts/resticctl.sh check 
```

##### Mount a repository as a drive (needs FUSE)

```bash
sudo /usr/local/scripts/resticctl.sh mount /mnt/restic
```

##### Snapshot diff (what was backed up):

```bash
sudo /usr/local/scripts/resticctl.sh snapshots
sudo /usr/local/scripts/resticctl.sh diff <snapshot1> <snapshot2> 
``` 
