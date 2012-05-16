#!/bin/bash

set -e
set -x

MODE="incr"
DAY_OF_WEEK_AS_NUMBER="$(date +%u)"
VOLSIZE=100
if [ "$DAY_OF_WEEK_AS_NUMBER" -eq 6 ] ; then
    MODE="full"
fi

### Prepare mysql snapshots
for db in $(find /var/lib/mysql/ -mindepth 1 -maxdepth 1 -type d | sed 's,/var/lib/mysql/,,')
do
    mysqldump -uroot --single-transaction -p"$(cat /root/passwords/mysql-root-password)" "$db" | gzip | sponge /var/backups/mysql/"$db".sql.gz
done

function do_backup() {
    TARGET="backups/linode.openhatch.org/$1"
    LOCAL_PATH="$2"
    ssh rsync.net mkdir -p "$TARGET"
    PASSPHRASE='' duplicity --encrypt-key="A5CC321E" cleanup --force scp://rsync.net/"$TARGET"
    duplicity remove-all-but-n-full 4 --force scp://rsync.net/"$TARGET"
    duplicity $MODE --exclude /var/lib/roundup/trackers/bugs/db/text-index/ --exclude /var/log/mysql/mysql-slow.log --exclude /var/log/memcached.log --exclude /tmp --exclude /var/lib/mysql --exclude /usr/share/locale --exclude /usr/share/doc --exclude /var/tmp --exclude /var/cache --exclude-other-filesystems --encrypt-key="A5CC321E" --volsize "$VOLSIZE" "$LOCAL_PATH" scp://rsync.net/"$TARGET"
}

do_backup "all" "/"
