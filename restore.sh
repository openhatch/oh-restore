#!/bin/bash

function remote_do() {
    ssh -t -t root@"$REMOTE_IP" "$@"
}

function copy_file() {
    scp "$1" root@"$REMOTE_IP":"$2"
}

function die() {
    echo "$1"
    exit 1
}

# ZEROth:
source restore.conf.sh

# First, make sure we can SSH there
ssh -o StrictHostKeyChecking=no root@"$REMOTE_IP" /bin/true || die "Can't SSH in."
echo "Logging in to $REMOTE_IP and getting to work."

ssh -t -t root@"$REMOTE_IP" apt-get -y install screen duplicity rsync bash

# Second, make sure we have all the required data
[[ -d conf ]] || die "Can't find configuration files. Ask Asheesh for these."
[[ -d secrets ]] || die "Can't find authentication secrets. Ash Asheesh for these."

# Put the right secrets and conf in the right places
remote_do mkdir -p /root/.ssh
remote_do chmod 700 /root/.ssh
copy_file conf/known_hosts /root/.ssh/known_hosts
copy_file conf/ssh_config /root/.ssh/config
copy_file secrets/ssh-key /root/.ssh/id_rsa
copy_file secrets/ssh-key.pub /root/.ssh/id_rsa.pub
remote_do chmod 600 /root/.ssh/'*'

remote_do mkdir -p /root/.gnupg
remote_do chmod 700 /root/.gnupg
cat secrets/gpg-secret-key.asc  | remote_do gpg --import

# Do a restore
ssh -t -t root@"$REMOTE_IP" PASSPHRASE='' duplicity --encrypt-key="A5CC321E" restore scp://rsync.net/backups/linode.openhatch.org/all /var/backups/restored

# Copy these files over
ssh root@"$REMOTE_IP" mkdir -p /var/backups/restored/restore-scripts
rsync -avzP . root@"$REMOTE_IP":/var/backups/restored/restore-scripts/.

# Run them
ssh -t -t root@"$REMOTE_IP" chroot /var/backups/restored 'bash -c "cd /restore-scripts ; make"'
