MYSQL_ROOT_PASSWORD='root'

# WordPress Documentation: https://codex.wordpress.org/Installing_WordPress
function installPHP(){
	sudo apt-get install software-properties-common
	sudo add-apt-repository -sy ppa:ondrej/php
	sudo add-apt-repository -sy ppa:ondrej/nginx-mainline
	sudo apt update
}

function checkPHPPackages(){
	for i in $*
	do
		find=$(dpkg --list | grep "${i}");
		if [ "$find" == 0 ]
		then 
			sudo apt install -y "$i";
		fi;
	done
	sudo systemctl restart nginx.service
	sudo systemctl restart php7.2-fpm.service
	echo "all required packages are installed";
}

# WordPress Documentation: https://codex.wordpress.org/Installing_WordPress
function installNginx(){
	sudo apt install -y nginx;
}

# WordPress Documentation: https://codex.wordpress.org/Installing_WordPress
function installMySql(){
	echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
	echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
	sudo apt install -y mysql-server
}


# A github repo code: https://gist.github.com/irazasyed/a7b0a079e7727a4315b9
function addHost() {
    DOMAIN_NAME=$1
    HOSTS_LINE="$IP\t$DOMAIN_NAME"
    if [ -n "$(grep $DOMAIN_NAME /etc/hosts)" ]
        then
            echo "$DOMAIN_NAME already exists : $(grep $DOMAIN_NAME $ETC_HOSTS)"
        else
            echo "Adding $DOMAIN_NAME to your $ETC_HOSTS";
            sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

            if [ -n "$(grep $DOMAIN_NAME /etc/hosts)" ]
                then
                    echo "$DOMAIN_NAME was added succesfully \n $(grep $DOMAIN_NAME /etc/hosts)";
                else
                    echo "Failed to Add $DOMAIN_NAME, Try again!";
            fi
    fi
}



###################################################################################################################

find=$(dpkg --list | grep 'php7.2-cli');
if [ "$find" == 0 ]
then 
	#echo "in install php";
	installPHP;
else
	echo "php is already installed";
fi;


checkPHPPackages php7.2-fpm php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-mysql php7.2-cli php7.2-zip php7.2-curl

if ! which nginx > /dev/null 2>&1
then
	installNginx;
else
	echo "Nginx is already installed";
fi

if ! which mysql > /dev/null 2>&1
then
	installMySql;
else
	echo "MySql is already installed";
fi

sudo systemctl restart nginx.service
sudo systemctl restart php7.2-fpm.service

addHost




