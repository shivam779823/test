#!/bin/bash

# Variables
DB_NAME="wordpressdb"
DB_USER="wordpressuser"
DB_PASSWORD="yourpassword"
WP_DIR="/var/www/html/wordpress"
WP_URL="http://your-domain.com"  # Replace with your domain or server IP

# Update package list
sudo apt update

# Install Nginx, MySQL, PHP, and other dependencies
sudo apt install -y nginx mysql-server php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

# Secure MySQL installation
sudo mysql_secure_installation

# Create a MySQL database and user for WordPress
sudo mysql -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Download and configure WordPress
sudo wget -c https://wordpress.org/latest.tar.gz -P /tmp
sudo tar xf /tmp/latest.tar.gz -C /tmp
sudo mv /tmp/wordpress/* ${WP_DIR}
sudo cp ${WP_DIR}/wp-config-sample.php ${WP_DIR}/wp-config.php

# Set up WordPress configuration
sudo sed -i "s/database_name_here/${DB_NAME}/" ${WP_DIR}/wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" ${WP_DIR}/wp-config.php
sudo sed -i "s/password_here/${DB_PASSWORD}/" ${WP_DIR}/wp-config.php

# Adjust permissions
sudo chown -R www-data:www-data ${WP_DIR}
sudo chmod -R 755 ${WP_DIR}

# Configure Nginx for WordPress
cat <<EOL | sudo tee /etc/nginx/sites-available/wordpress
server {
    listen 80;
    server_name ${WP_URL};
    root ${WP_DIR};
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock; # Use the correct PHP version if different
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

# Test Nginx configuration and restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# Clean up
sudo rm -rf /tmp/latest.tar.gz /tmp/wordpress

# Display completion message
echo "WordPress with Nginx has been successfully installed. Visit ${WP_URL} to complete the setup."
