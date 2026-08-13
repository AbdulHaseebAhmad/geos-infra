
#!/bin/bash

apt-get update -y
apt-get install -y nginx
sudo mkdir -p /var/www/geos-backend
sudo mkdir -p /var/www/geos-frontend

sudo chown ubuntu:ubuntu /var/www/geos-backend
sudo chown ubuntu:ubuntu /var/www/geos-frontend

cat <<EOF > /etc/systemd/system/geos-backend.service
[Unit]
Description=GEOS Backend Service
After=network.target

[Service]
ExecStart=/var/www/geos-backend/geos-backend
Restart=always
User=ubuntu
WorkingDirectory=/var/www/geos-backend

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable geos-backend

systemctl enable nginx
systemctl start nginx
