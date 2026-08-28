#!/bin/bash

apt-get update -y

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install

apt-get install -y nginx
apt-get install -y postgresql-client

sudo mkdir -p /var/www/geos-backend
sudo mkdir -p /var/www/geos-frontend

sudo chown ubuntu:ubuntu /var/www/geos-backend
sudo chown ubuntu:ubuntu /var/www/geos-frontend

sudo apt-get install -y postgresql-client
apt-get install -y jq


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
secret_arn: "__SECRET_ARN__"
rds_endpoint: "__RDS_ENDPOINT__"
http_server:
  Address: "0.0.0.0:8000"
smtp:
  Host: ""
  Sender: ""
  Password: ""
  Port: ""
EOF

DB_SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "__SECRET_ARN__" \
    --query SecretString \
    --output text)

DB_USERNAME=$(echo "$DB_SECRET_JSON" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_SECRET_JSON" | jq -r '.password')

PGPASSWORD="$DB_PASSWORD" psql \
    -h "__RDS_ENDPOINT__" \
    -U "$DB_USERNAME" \
    -d postgres \
    -c 'CREATE DATABASE "edu-connect";' 2>/dev/null || true

systemctl daemon-reload
systemctl enable geos-backend

systemctl enable nginx
systemctl start nginx
nginx -t
systemctl reload nginx
