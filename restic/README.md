## A restic-based backup system on a family PC

This is a copy of a version controlled [restic/README.md](git@github.com:oldlance/ldf-config.git) file in github, which should be the source of truth.

The following is based on an installation on FreeBSD 14 using GCS as storage which was the first storage used.  It is almost certain that the scripts will have to be tweaked to run on another distribution and/or for other storage types, as will the include and exclude files.  For now, treat restic configuration and script files as readonly on non-FreeBSD systems.  The README.md file should be maintained, though.

On non-FreeBSD systems, I've tended to use `/root/.config/restic/` as the equivalent of `/usr/local/etc` and `/usr/local/bin` as the equivalent of `/usr/local/scripts`.  However, because I've decided to use GNU Stow, over time I'll be making all installations uniform.

In mid-2025 I noticed that GCS costs were creeping up and also discovered during my reading about `restic` that the separate-folder-per-host configuration that I'd chosen was not optimal for restic's deduplication. So, I decided to give 1TB [Hetzner Storage Box](https://console.hetzner.com/projects/11407998/storage-boxes/461530/overview) a go.

### Current installation status (02/09/2025)

| Host     | GCS    | Hetzner | Status |
| ------   | :----: | :----:  | ----   |
| archie   | x      | X      |        |
| atlas    | X      | X       |        |
| ganymede | X      |         |        |
| hub      | X      | X       |        |
| immich   | X      |         |        |
| io       | X      |         |        |
| jupiter  | X      |         |        |
| pan      | x      | X       |        |

**x** == can run; **X** == can run and is configured to run


### Installation 

Backup up is supported to either Google Cloud Storage or Hetzner Storage Box.  The key differences between the two targets is 
- the authentication process (service account vs SSH certificate based auth).
- GCS is configure to use one repo per host where as Hetzner is configured to store all host's backups in a single repo.  The latter approach is preferred as it means that restic's deduplication works much better.  This means that the command-lines for restic backup and forget are slightly different (Hetzner includes a group-by host options that isn't use for Google).

It is assumed in the instructions below that you've created a GCS bucket and service account and have the key to hand in a file called something like `home-data-storage-xxxysys.json`.  It is also assumed that you've set up Hetzner specific ssh keys and a config file in root's `.ssh` such as the one shown below that allows you to sftp into Hetzner. Also, that you've created a directory called `restic-backups` in the root of the Hetzner storage.

```
#$HOME/.ssh/config

# Avoids having to enter private keys more than once per session
AddKeysToAgent yes

# Allows on to address Hetzner storage as 'french-restic-repo'.
# #.g: sftp french-restic-repo
Host french-restic-repo
    HostName u478266.your-storagebox.de
    Port 23
    User u478266
    IdentityFile ~/.ssh/id_rsa_hetzner_restic
    ServerAliveInterval 60
    ServerAliveCountMax 240
```

1. As root, create the necessary subdirectories:

    ```bash
    sudo -s
    mkdir -p /usr/local/etc/restic /usr/local/scripts /usr/local/var/backups /var/log/restic
    ```
2. Install `restic`

    ```bash
    sudo pkg install restic
    ```
3. Install 
   
   - Scripts & configuration files 
     These will be installed using GNU stow - see [Shared configuration setup (with GNU Stow)](shared configuration setup.md)
        - `/usr/local/scripts/{restic-backup.sh,resticctl.sh[,postgres-backup.sh]}`
        - `/usr/local/etc/restic/{restic-backup.conf,include-in-backup-<hostname>,exclude-from-backup-<hostname>}`
     Ensure that the <hostname> files for the new host are created.
   
   - Service keys & password files  (remember to chmod 600 so that only root can see them)
        - `/usr/local/etc/restic/{.restic-backup-password,.home-data-storage-xxxysys.json}`

4. Set permissions so that only root may access files:

    ```bash
    chown -R root:wheel /usr/local/etc/restic*
    chmod 600 /usr/local/etc/restic/*
    chmod 777 /usr/local/var/backups  #  other users should be able store files in this catch-all backups directory (eg postgres)
    ```
5. Set up root's crontab by running `sudo crontab -e` and entering:
   Ensure you replace _<target>_ with your choice of _hetzner_ or _google_

    ```bash
    # Run restic to backup data to GCS every day at 04:05am; also 2 minutes after rebooting.
    05 04 * * * /usr/local/scripts/restic-backup.sh <target> >>/var/log/restic/backup.log 2>&1
    @reboot     sleep 120 && /usr/local/scripts/restic-backup.sh <target> >>/var/log/restic/backup.log 2>&1
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
    
7. Initialise the repository.

    ```bash
    resticctl.sh {hetzner|google} init
    ```

If you find that restic has trouble understanding the --group-by option (ie reports an error) they you are most likely running an old version.  Updates seems to fix it:  `sudo restic self-update` FTW!

If you find that backups are failing with `... lost connection ...` error messages, the you need to switch to using `rclone`, which has better `ssh` handling than `restic`, as an intermediate comms layer.  I have had to do this for the Hetzner backups on both the `restic` jail on `jupiter` and the `immich` VM on Proxmox. Note that `rclone` uses its own config and that the `rclone` destination URL needs a different format.  See the `rclone` and `restic` docs for examples.

### Useful  info

Online docs available [here](https://restic.readthedocs.io/en/stable/010_introduction.html)

GCS cloud storage is owned by ldffrench@gmail.com (credentials in BitWarden).  Backups live in bucket *french-family-restic-backups*.  Each host has its own 'directory' (eg ganymede, io, jupiter)

Hetzner Storage box is owned by lance@frenchathome.net (credentials in BitWarden).  Backups live in directory *restic-backups*.  Backups from all hosts go into this directory; to filter on a particular hosts use the option `--host=hostname`.  Note that it is sometimes necessary to use the full name - eg `--host=archie.home.arpa`.

The desired target is given as the first option to the scripts.  That is `./resticctl.sh {google|hetzner}` and `./restic-backup.sh {google|hetzner}`.

Progress is logged to `/var/log/restic/backup.log`

##### Used storage space

Working out how much space is being used on the destination is not intuitive.  The command to uses is **stats** but the default mode (*restore-size*) is to respond with how much space would be required to restore the snapshot named in the command.  If a snapshot name is not given then it sums the size of all restoring all snapshots in sequence.  To see how much space is being consumed on the remote use mode *raw-data*.

```bash
sudo /usr/local/scripts/resticctl.sh google stats --mode=raw-data
```
For example, if I look at how much space is used by jupiter in GCS using `gsutil du -h -s -a gs://french-family-restic-backups/jupiter`.  But if I run `sudo /usr/local/scripts/resticctl.sh google stats` I get 11TB!!!.  `--mode=raw-data` agrees with `gsutil du ...` 

##### List snapshots:

```bash
sudo /usr/local/scripts/resticctl.sh hetzner snapshots
``` 

##### Check metadata integrity

```bash
sudo /usr/local/scripts/resticctl.sh google check 
```

##### Mount a repository as a drive (needs FUSE)

```bash
sudo /usr/local/scripts/resticctl.sh hetzner mount /mnt/restic
```

##### Snapshot diff (what was backed up):

```bash
sudo /usr/local/scripts/resticctl.sh hetzner snapshots
sudo /usr/local/scripts/resticctl.sh hetzner diff <snapshot1> <snapshot2> 
``` 
<hr>

<span style="font-size: 34px;">** >>>>>> LEGACY instructions (pre October 2025) <<<<<< **</span>

The instructions below were relevant before the scripts were refactored to be paramaterized by target and before GNU Stow was introduced.  

### LEGACY Installation - Google Cloud Storage LEGACY
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
    
7. Initialise the repository.  **Remember to confirm that both `resticctl.conf` and `restic-backup.conf` have been changed to include the current value of `hostname -s` in the bucket path.**

    ```bash
    resticctl.sh init
    ```

### LEGACY Installation - Hetzner Storage Box

I used this [article as a guide](https://glueck.dev/blog/using-restic-on-windows-to-backup-to-a-hetzner-storage-box).

**NB:** it is important to group by _host_ when backing up multiple hosts to a single repository.  This means using `--group-by 'host'` in the script.

1. As root, create the necessary subdirectories:

    ```bash
    sudo -s
    mkdir -p /usr/local/etc/restic-backup-hetzner /usr/local/etc/resticctl-hetzner /usr/local/scripts /usr/local/var/backups /var/log/restic
    ```
2. Install `restic`

    ```bash
    sudo pkg install restic
    ```
3. Install scripts, configuration files and SSH keys: 
   - `/usr/local/etc/restic-backup-hetzner/{retic-backup-hetzner.conf,include-in-backup,exclude-from-backup}`
   - `/usr/local/etc/resticctl-hetzner/{reticctl-hetzner.conf}`
   - `/usr/local/scripts/{restic-backup-hetzner.sh,resticctl-hetzner.sh}`
   - `/root/.ssh/id_rsa_hetzner_restic`
   - `/root/.ssh/config`

4. Set permissions so that only root may access files:

    ```bash
    chown -R root:wheel /usr/local/etc/restic*
    chown -R root:wheel /usr/local/scripts
    chmod 750 /usr/local/etc/{resticctl-hetzner,restic-backup-hetzner}
    chmod 600 /usr/local/etc/{resticctl-hetzner,restic-backup-hetzner}/*
    chmod 750 /usr/local/scripts/*
    chmod 777 /usr/local/var/backups  #  other users should be able store files in this catch-all backups directory (eg postgres)
    ```
    
5. Initialise the repo (this only has to be done one per repository)

    ```bash
    # add hetzner storage to known-hosts
    ssh french-restic-repo
    
    # init the repo 
    source /usr/local/etc/restic-backup-hetzner/restic-backup-hetzner.conf
    restic init
    ```

6. Set up root's crontab by running `sudo crontab -e` and entering:

    ```
    # Run restic to backup data to Hetzner Storage Box every day at 04:05am; also 2 minutes after rebooting.
    05 04 * * * /usr/local/scripts/restic-backup-hetzner.sh >>/var/log/restic/backup-hetzner.log
    @reboot     sleep 120 && /usr/local/scripts/restic-backup-hetzner.sh >>/var/log/restic/backup-hetzner.log
    ```
7. Set up log rotation:

    ```bash
    # FreeBSD: /usr/local/etc/newsyslog.conf.d/restic-backup-newsyslog.conf
    /var/log/restic/backup-hetzner.log   root:wheel  644    10  1024  *  -
    
    # ArchLinux: /etc/logrotate.d/restic-backup
    /var/log/restic/backup-hetzner.log {
    create 0644 root wheel
    rotate 10
    size 1024k
    notifempty
    missingok
    copytruncate
    }
    ```
