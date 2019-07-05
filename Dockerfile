FROM debian:stable-slim

LABEL maintainer="Michael Nival <docker@mn-home.fr>" \
	name="debian-zabbix"

RUN printf "deb http://ftp.debian.org/debian/ stable main\ndeb http://ftp.debian.org/debian/ stable-updates main\ndeb http://security.debian.org/ stable/updates main\n" >> /etc/apt/sources.list.d/stable.list && \
	cat /dev/null > /etc/apt/sources.list && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt update && \
	apt -y --no-install-recommends full-upgrade && \
	echo "UTC" > /etc/timezone && \
	rm /etc/localtime && \
	dpkg-reconfigure tzdata && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

RUN apt update && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt -y --no-install-recommends install wget ca-certificates && \
	export ZABBIX_RELEASE="zabbix-release_4.2-1+stretch_all.deb" && \
	wget https://repo.zabbix.com/zabbix/4.2/debian/pool/main/z/zabbix-release/${ZABBIX_RELEASE} -O /tmp/${ZABBIX_RELEASE} && \
	dpkg -i /tmp/${ZABBIX_RELEASE} && \
	rm /tmp/${ZABBIX_RELEASE} && \
	apt -y purge wget ca-certificates && \
	apt -y autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

RUN apt update && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt -y --no-install-recommends install zabbix-server-mysql mariadb-server && \
	/etc/init.d/mysql start && \
	printf "create database zabbix character set utf8 collate utf8_bin;\ngrant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';\nquit\n" | mysql && \
	cd /tmp && apt download zabbix-server-mysql && \
	dpkg -x zabbix-server-mysql*.deb /tmp/zabbix-server-mysql/ && \
	zcat /tmp/zabbix-server-mysql/usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -pzabbix zabbix && \
	rm -r /tmp/zabbix-server-mysql* && \
	sed -i 's/^\(# DBPassword.*\)/\1\nDBPassword=zabbix/g' /etc/zabbix/zabbix_server.conf && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

RUN apt update && \
	export DEBIAN_FRONTEND=noninteractive && \
	apt -y --no-install-recommends install nginx php-fpm php && \
	apt -y --no-install-recommends install zabbix-frontend-php && \
	apt -y --no-install-recommends install zabbix-agent && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/alternatives.log /var/log/dpkg.log /var/log/apt/ /var/cache/debconf/*-old

ADD nginx-zabbix.conf /etc/nginx/conf.d/zabbix.conf
ADD php-zabbix.conf /etc/php/7.0/fpm/conf.d/99-zabbix.ini
ADD zabbix.conf /etc/zabbix/web/zabbix.conf.php
