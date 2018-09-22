set -ev

# exit if required programs arent installed
hash wget || exit 1
hash nginx || exit 1
hash certbot || exit 1

wget https://github.com/usefathom/fathom/releases/download/latest/fathom-linux-amd64
mv fathom-linux-amd64 /usr/local/bin/fathom
chmod +x /usr/local/bin/fathom

mkdir /opt/fathom
secret=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 25 ; echo '')
cat > /opt/fathom/fathom.env <<EOL
FATHOM_SERVER_ADDR=9000
FATHOM_DATABASE_DRIVER="sqlite3"
FATHOM_DATABASE_NAME="fathom.db"
FATHOM_SECRET=$secret
EOL

echo 'Enter your email:'
read -r EMAIL
echo 'Enter your password:'
read  -r PASSWORD

fathom --config=/opt/fathom/fathom.env register --email="$EMAIL" --password="$PASSWORD"

echo 'Enter your domain name:'
read -r DOMAIN

cat > /etc/nginx/sites-enabled/"$DOMAIN" <<EOL
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

nginx -t

nginx -s reload

cat > /etc/systemd/system/fathom.service <<EOL
[Unit]
Description=Starts the fathom server
Requires=network.target
After=network.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=3
ExecStart=/usr/local/bin/fathom --config=/opt/fathom/fathom.env server

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable fathom

systemctl start fathom

certbot --nginx -d "$DOMAIN"
