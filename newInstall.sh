
WP_DOMAIN="blog.bvzzdesign.com"
WP_ADMIN_USERNAME="admin"
WP_ADMIN_PASSWORD="admin"
WP_ADMIN_EMAIL="no@spam.org"
WP_DB_NAME="wordpress"
WP_DB_USERNAME="wordpress"
WP_DB_PASSWORD="wordpress"
WP_PATH="/var/www/wordpress"
MYSQL_ROOT_PASSWORD="root"

echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
sudo apt install -y nginx mysql-server

sudo service apache2 stop

sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo add-apt-repository ppa:ondrej/nginx-mainline
sudo apt update

sudo apt install php7.2-fpm php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-mysql php7.2-cli php7.2-zip php7.2-curl

sudo systemctl restart nginx.service
sudo systemctl restart php7.2-fpm.service

sudo mkdir -p $WP_PATH/public $WP_PATH/logs
sudo tee /etc/nginx/sites-available/$WP_DOMAIN <<EOF
server {
listen 80;
listen [::]:80;
server_name $WP_DOMAIN www.$WP_DOMAIN;

root $WP_PATH/public;
index index.php;

access_log $WP_PATH/logs/access.log;
error_log $WP_PATH/logs/error.log;

location / {
try_files \$uri \$uri/ /index.php?\$args;
}

location ~ \.php\$ {
include snippets/fastcgi-php.conf;
fastcgi_pass unix:/run/php/php7.2-fpm.sock;
}
}
EOF

sudo ln -s /etc/nginx/sites-available/$WP_DOMAIN /etc/nginx/sites-enabled/

sudo nginx -t

sudo service nginx restart

mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE USER '$WP_DB_USERNAME'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';
CREATE DATABASE $WP_DB_NAME;
GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USERNAME'@'localhost';
EOF


sudo rm -rf $WP_PATH/public/ # !!!
sudo mkdir -p $WP_PATH/public/
sudo chown -R $USER $WP_PATH/public/
cd $WP_PATH/public/

wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1
rm latest.tar.gz

mv wp-config-sample.php wp-config.php
sed -i s/database_name_here/$WP_DB_NAME/ wp-config.php
sed -i s/username_here/$WP_DB_USERNAME/ wp-config.php
sed -i s/password_here/$WP_DB_PASSWORD/ wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php

sudo chown -R www-data:www-data $WP_PATH/public/

curl "http://$WP_DOMAIN/wp-admin/install.php?step=2" \
--data-urlencode "weblog_title=$WP_DOMAIN"\
--data-urlencode "user_name=$WP_ADMIN_USERNAME" \
--data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
--data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
--data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
--data-urlencode "pw_weak=1"

