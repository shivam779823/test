#!/bin/bash

# Define variables
APP_NAME="myflaskapp"
APP_DIR="/var/www/${APP_NAME}"
APP_SCRIPT="app.py"
NGINX_CONFIG="/etc/nginx/sites-available/${APP_NAME}"
DOMAIN="example.com"  # Replace with your domain name or IP address
GUNICORN_PORT="8000"

# Update system packages
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip nginx

# Install Flask and Gunicorn
pip3 install flask gunicorn

# Create a directory for your Flask app
sudo mkdir -p $APP_DIR

# Copy your Flask app script to the app directory
sudo cp $APP_SCRIPT $APP_DIR

# Create a Gunicorn service file
sudo tee /etc/systemd/system/${APP_NAME}.service <<EOF
[Unit]
Description=Gunicorn instance to serve ${APP_NAME}
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/gunicorn --workers 4 --bind 0.0.0.0:$GUNICORN_PORT $APP_SCRIPT:app

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the Gunicorn service
sudo systemctl start ${APP_NAME}
sudo systemctl enable ${APP_NAME}

# Create an Nginx server block configuration file
sudo tee $NGINX_CONFIG <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$GUNICORN_PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /static {
        alias $APP_DIR/static;
    }

    location /favicon.ico {
        alias $APP_DIR/static/favicon.ico;
    }

    location /robots.txt {
        alias $APP_DIR/static/robots.txt;
    }

    location /uploads {
        alias $APP_DIR/uploads;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

# Enable the Nginx server block
sudo ln -s $NGINX_CONFIG /etc/nginx/sites-enabled/

# Test Nginx configuration and reload
sudo nginx -t
sudo systemctl reload nginx

# Allow incoming traffic on port 80 (HTTP)
sudo ufw allow 80/tcp

# Print completion message
echo "Your Flask app is now hosted with Nginx at http://$DOMAIN"
