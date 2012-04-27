#!/bin/bash

function die() {
    echo "$1"
    exit 1
}

# ZEROth:
source restore.conf.sh

# First, make sure we can SSH there
ssh root@"$REMOTE_IP" /bin/true || die "Can't SSH in."

ssh -t root@"$REMOTE_IP" apt-get install screen duplicity rsync bash

# Second, make sure we have all the required data
[[ -d conf ]] || die "Can't find configuration files. Ask Asheesh for these."
[[ -d secrets ]] || die "Can't find authentication secrets. Ash Asheesh for these."

# Do a restore
ssh -t root@"$REMOTE_IP" duplicity --encrypt-key="A5CC321E" restore scp://rsync.net/backups/linode.openhatch.org/all /var/backups/restored

# Copy these files over
ssh root@"$REMOTE_IP" mkdir -p /var/backups/restored/restore-scripts
rsync -avzP . root@"$REMOTE_IP":/var/backups/restored/restore-scripts/.

# Run them
ssh -t root@"$REMOTE_IP" chroot /var/backups/restored 'bash -c "cd /restore-scripts ; make"'
