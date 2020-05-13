#!/bin/bash

NGINX_DIR="/etc/nginx"
BINARIES=( ntp expect libselinux-python policycoreutils-python unzip zip bash-completion bind-utils nmap-ncat unzip
           yum-plugin-versionlock policycoreutils setroubleshoot vim yum-utils htop iotop tcpdump mc sysstat wget )
# Setup NGINX and Java
yum install epel-release nginx -y
systemctl enable nginx

yum install java-11-openjdk-devel-11.0.6.10 -y
rm -rf $NGINX_DIR/conf.d/*.conf

mkdir -p $NGINX_DIR/conf.d/ $NGINX_DIR/conf.d/ssl/
chmod 755 $NGINX_DIR/conf.d/ $NGINX_DIR/conf.d/ssl/ /etc/logrotate.d/

semanage port -a -t http_port_t -p tcp 10061
semanage port -a -t http_port_t -p tcp 8060
setsebool -P httpd_can_network_connect 1
setsebool -P nis_enabled 1

timedatectl set-timezone Europe/Riga

#Install packages
for i in "${BINARIES[@]}"
do
  yum install $i -y
done
