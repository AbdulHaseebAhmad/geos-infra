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
ExecStart=/var/www/geos-backend/geos-backend --config_path=/var/www/geos-backend/prodConfig.yaml
Restart=always
User=ubuntu
WorkingDirectory=/var/www/geos-backend

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;

    location / {
        root /var/www/geos-frontend;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

systemctl daemon-reload
systemctl enable geos-backend

systemctl enable nginx
systemctl start nginx
nginx -t
systemctl reload nginx
