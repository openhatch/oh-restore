#!/bin/bash

function die() {
    print "$1"
    exit 1
}

# ZEROth:
source restore.conf.sh

# First, make sure we can SSH there
ssh root@"$RESTORE_IP" /bin/true || die "Can't SSH in."

# Second, make sure we have all the required data
[ -f conf ] || die "Can't find configuration files. Ask Asheesh for these."
[ -f secrets ] die "Can't find authentication secrets. Ash Asheesh for these."

# Then copy these files there
ssh root@"$RESTORE_IP" mkdir -p /root/restore
rsync -avzP . root@"$RESTORE_IP":/root/restore/.

# Then, tell the user what to do
echo "Now, do:"
echo "    "ssh root@"$RESTORE_IP"
echo "create a GNU screen session, cd /root/restore; and run 'make'"
