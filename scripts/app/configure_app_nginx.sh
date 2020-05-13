#!/bin/bash

NGINX_DIR="/etc/nginx"
PRIVATE_IP=$(hostname -I | awk '{print $1}')
PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCscfDxTgqx32lZwNqvf96dPNqJL/SKD26ApJdU+Rxyl3Y7tIpB9uGX6fYjo7Dd5kuM7Dhv/R06TKq3RSW2yUu86yDzojiz0gRClS/SRZGQgXIeCOysB0VRLAAUTAnGjOYz90IuJYigpo/g2nauEmUeirQ7WLDv0/1Od/BaM8GMMfcC/bqgUPnhCNgxfoydf0p74wOpltBbyUwQ//xMhhzgDmrMIE5LNzHxlu/QWNJ9mIMs83nJawg9nvYUfw54alJkHDJ7bttAMC8hp6rZnr0gU4HIURXIxxyvQm7fxwgo898WRh6LPGyiZC5eC6fqq/uLOIxJHhY/KbB4xjLpEuBj LV prod deploy key"
# Configure NGINX
setsebool -P httpd_setrlimit on

mv /tmp/nginx.conf $NGINX_DIR/
mv /tmp/nginx /etc/logrotate.d/
mv /tmp/dhparam.pem $NGINX_DIR/conf.d/ssl/
mv /tmp/nginx_status.conf $NGINX_DIR/conf.d/
mv -f /tmp/sshd_config.conf /etc/ssh/sshd_config
sed -i 's/ListenAddress localhost/ListenAddress ${PRIVATE_IP}/' /etc/ssh/sshd_config
systemctl restart sshd
chown nginx:nginx /var/log/nginx
chown nginx:nginx $NGINX_DIR/conf.d/ssl/dhparam.pem

#ADD users
groupadd app_deploy_users
useradd lv-prod-deploy
useradd deploy
mkdir /home/lv-prod-deploy/.ssh
mkdir /home/deploy/.ssh
echo $PUB_KEY >> /home/lv-prod-deploy/.ssh/authorized_keys
echo $PUB_KEY >> /home/deploy/.ssh/authorized_keys
chmod 644 /home/lv-prod-deploy/.ssh/authorized_keys
chmod 644 /home/deploy/.ssh/authorized_keys
chmod 700 /home/lv-prod-deploy/.ssh/
chmod 700 /home/deploy/.ssh/
usermod -aG app_deploy_users lv-prod-deploy
mkdir /home/deploy/base
chown deploy:deploy /home/deploy/base
chmod 755 /home/deploy/base

mv /tmp/sudo_operations_group /etc/sudoers.d/sudo_operations_group
chmod 440 /etc/sudoers.d/sudo_operations_group
chown root:root /etc/sudoers.d/sudo_operations_group

# Configure rsyslog
sed -i '#$ModLoad imudp/$ModLoad imudp ' /etc/rsyslog.conf
sed -i '#$UDPServerRun 514/$UDPServerRun 514' /etc/rsyslog.conf
sed -i '#$ModLoad imtcp/$ModLoad imtcp' /etc/rsyslog.conf
sed -i '#$InputTCPServerRun 5140/$InputTCPServerRun 5140' /etc/rsyslog.conf
sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config

#Configure monitoring
useradd node_exporter
wget -P /usr/bin/ https://storage.googleapis.com/flexidea-resources/data/node_exporter_0.16.0
mv /usr/bin/node_exporter_0.16.0 /usr/bin/node_exporter
chmod 755 /usr/bin/node_exporter
mv /tmp/node_exporter.service /usr/lib/systemd/system/node_exporter.service
chmod 744 /usr/lib/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter


