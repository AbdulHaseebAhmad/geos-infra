#!/bin/bash

apt-get update -y
apt-get install -y nginx
apt-get install -y postgresql-client

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

cat <<EOF > /var/www/geos-backend/prodConfig.yaml
env: production
secret_arn: "arn:aws:secretsmanager:us-east-1:329599643204:secret:rds!db-89c6cec8-de6e-4ff3-9656-d94cd39ab7d1-1UTlYS"
rds_endpoint: "geos-db-instance.c7uskuk88uxd.us-east-1.rds.amazonaws.com"
http_server:
  Address: "0.0.0.0:8000"
smtp:
  Host: "smtp.gmail.com"
  Sender: "abdull.haseebkhan@gmail.com"
  Password: "hzohskgaiuyxcrgw"
  Port: "465"
EOF

systemctl daemon-reload
systemctl enable geos-backend

systemctl enable nginx
systemctl start nginx
nginx -t
systemctl reload nginx
