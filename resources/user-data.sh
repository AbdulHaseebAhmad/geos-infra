
#!/bin/bash

apt-get update -y
apt-get install -y nginx
mkdir -p /var/www/geos-backend
mkdir -p /var/www/geos-frontend
systemctl enable nginx
systemctl start nginx
