DEBIAN_FRONTEND := noninteractive
export DEBIAN_FRONTEND

all: run

/proc:
	mkdir -p /proc
	mount /proc

/sys:
	mkdir -p /sys
	mount /sys

udev-start:
	/etc/init.d/udev restart

google-dns:
	echo nameserver 8.8.8.8 > /etc/resolv.conf

/tmp:
	mkdir -m 1777 /tmp

fake-dns:
	grep -v linode.openhatch.org /etc/hosts | sponge /etc/hosts
	echo $$(ip  addr | grep 'inet ' | grep -v 'inet 10[.]' | grep -v 'inet 127[.]' | awk '{print $2}' | sed 's,/.*,,' | sed 's/inet //') linode.openhatch.org openhatch.org >> /etc/hosts

system-setup: /proc /sys /tmp udev-start google-dns fake-dns

restore-database: mysql-install mysql-restore

restore-apt:
	mkdir -p /var/cache/etckeeper
	mkdir -p /var/cache/debconf
	mkdir -p /var/cache/apt/archives/partial

mysql-install:
	apt-get update
	apt-get -y install --reinstall mysql-server-5.1

mysql-restore:
	/etc/init.d/mysql stop
	/usr/bin/mysqld_safe --skip-grant-tables &
	sleep 4
	#cd /var/backups/mysql ; for thing in *.sql.gz; do db=$${thing%.sql.gz} ; echo create database $$db | mysql -uroot ; zcat "$$thing" | mysql -uroot $${thing%.sql.gz}; done
	/usr/bin/mysqladmin shutdown
	/etc/init.d/mysql restart

start-apache:
	/etc/init.d/apache2 restart

start-roundup:
	/etc/init.d/roundup restart

start-nginx:
	/etc/init.d/nginx restart

restore-web: start-apache start-roundup start-nginx

check:
	echo "import sys; import django.test.client ; c = django.test.client.Client() ; r = c.get('/') ; r.status_code == 200 or sys.exit(1)" | sudo -u deploy -H sh -c 'cd /home/deploy/milestone-a ;  python manage.py shell --plain'

run: system-setup restore-apt restore-database restore-web check