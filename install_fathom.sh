#!/usr/bin/env bash
set -e

# exit if required programs arent installed
hash wget || exit 1
hash nginx || exit 1
hash certbot || exit 1

wget https://github.com/usefathom/fathom/releases/download/latest-development/fathom-linux-amd64
sudo mv fathom-linux-amd64 /usr/local/bin/fathom
sudo chmod +x /usr/local/bin/fathom

if [ ! -d /opt/fathom ]; then
  sudo mkdir /opt/fathom
fi
secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 25 ; echo '')
envfile=$(cat <<EOL
FATHOM_SERVER_ADDR=9000
FATHOM_DATABASE_DRIVER="sqlite3"
FATHOM_DATABASE_NAME="/opt/fathom/fathom.db"
FATHOM_SECRET=$secret
EOL
)
echo "$envfile"| sudo tee /opt/fathom/fathom.env > /dev/null

(
cd /opt/fathom

echo 'Enter your email:'
read -r EMAIL
echo 'Enter your password:'
read  -rs PASSWORD

sudo fathom --config=/opt/fathom/fathom.env user add --email="$EMAIL" --password="$PASSWORD"
)

echo 'Enter your domain name:'
read -r DOMAIN

nginxconf=$(cat <<EOL
server {
	server_name "$DOMAIN";

	location / {
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$remote_addr;
		proxy_set_header Host \$host;
		proxy_pass http://127.0.0.1:9000; 
	}
}
EOL
)
echo "$nginxconf" | sudo tee /etc/nginx/sites-enabled/"$DOMAIN" > /dev/null

sudo nginx -t

sudo nginx -s reload

systemdunit=$(cat <<EOL
[Unit]
Description=Starts the fathom server
Requires=network.target
After=network.target

[Service]
Type=simple
User="$USER"
Restart=always
RestartSec=3
ExecStart=/usr/local/bin/fathom --config=/opt/fathom/fathom.env server

[Install]
WantedBy=multi-user.target
EOL
)
echo "$systemdunit" | sudo tee /etc/systemd/system/fathom.service > /dev/null

systemctl daemon-reload
systemctl enable fathom

systemctl start fathom

sudo certbot --nginx -d "$DOMAIN"
