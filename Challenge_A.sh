YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'

function okayGreen()
{
    echo -e "${GREEN}-----> $1"
}

function acceptableYellow()
{
    echo -e "${YELLOW}-----> $1"
}

function worstRed()
{
    echo -e "${RED}-----> $1"
}

function infoBlue(){
    echo -e "${BLUE}-----> $1"
}

function createDB(){
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
# SET GLOBAL validate_password_length = 6;
# SET GLOBAL validate_password_number_count = 0;
# SET GLOBAL validate_password_special_char_count = 0;
# SET GLOBAL validate_password_number_count = 0;
CREATE USER '$WP_DB_USERNAME'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';
CREATE DATABASE `$WP_DB_NAME`;
GRANT ALL ON `$WP_DB_NAME`.* TO '$WP_DB_USERNAME'@'localhost';
EOF
}

function createConfig(){
sudo tee /etc/nginx/sites-available/$DOMAIN_NAME <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

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
}

function installPackages(){
sudo apt install php7.2-fpm php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-mysql php7.2-cli php7.2-zip php7.2-curl

sudo systemctl restart nginx.service
sudo systemctl restart php7.2-fpm.service
}

###########################
#Task 1 : Check if PHP, Mysql & Nginx are installed. If not present, install the missing packages

infoBlue "Installing PHP"

sudo apt-get install software-properties-common
sudo add-apt-repository -sy ppa:ondrej/php
sudo add-apt-repository -sy ppa:ondrej/nginx-mainline
sudo apt update

infoBlue "PHP is successfully installed"

# infoBlue "Installing Nginx"
# sudo apt update
# sudo apt install nginx

# okayGreen "Nginx is successfully installed"

infoBlue "Installing MySql"
sudo apt update

MYSQL_ROOT_PASSWORD='root'

echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections

sudo apt install -y nginx mysql-server

installPackages

infoBlue "MySql is successfully installed"


#############################################################
#Task 2 : Ask the user for a domain name

infoBlue "Enter the Domain name of website : "
read DOMAIN_NAME
WP_DB_NAME="{$DOMAIN_NAME}_db"
infoBlue "Enter WordPress Admin UserID : "
read WP_ADMIN_USERNAME
infoBlue "Enter WordPress Admin EmailId : "
read WP_ADMIN_EMAIL
infoBlue "Enter WordPress Admin Password : "
read -s WP_ADMIN_PASSWORD
WP_PATH='/var/www/html'


############################################################
#Task 3 : Create a /etc/hosts entry for example.com pointing to localhost
sudo -- sh -c -e "echo '$DOMAIN_NAME' >> /etc/hosts"
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/$DOMAIN_NAME


############################################################
#Task 4 : Create an nginx config file for example.com
sudo mkdir -p $WP_PATH/public $WP_PATH/logs
createConfig
sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-available/default
#test configuration



############################################################
#Task 5 : Download the latest WordPress version and unzip it locally in example.com document root
sudo rm -rf $WP_PATH/public/ # !!!
sudo mkdir -p $WP_PATH/public/
sudo chown -R $USER $WP_PATH/public/
cd $WP_PATH/public/

wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1


############################################################
#Task 6 : Create a new Mysql database for WordPress with name “example.com_db”
createDB


############################################################
#Task 7 : Create a wp-config.php with proper DB configuration
mv wp-config-sample.php wp-config.php
sed -i s/database_name_here/$DOMAIN_NAME/ wp-config.php
sed -i s/username_here/$WP_DB_USERNAME/ wp-config.php
sed -i s/password_here/$WP_DB_PASSWORD/ wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php


############################################################
#Task 8 : Fix any file permissions, clean up temporary files and restart/reload Nginx config
sudo chown -R www-data:www-data $WP_PATH/public/
cd $WP_PATH/public/
rm latest.tar.gz

curl "http://$DOMAIN_NAME/wp-admin/install.php?step=2" \
--data-urlencode "weblog_title=$DOMAIN_NAME"\
--data-urlencode "user_name=$WP_ADMIN_USERNAME" \
--data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
--data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
--data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
--data-urlencode "pw_weak=1"
sudo nginx -t
sudo service nginx restart

okayGreen "200 OK : Web Server setup is completed"

echo "For visit the website go to http://$DOMAIN_NAME"



