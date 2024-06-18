#!/bin/bash



NFS_IP="x.x.x.x"
NFS_LOGS="folder/folder/folder"
NFS_DATA="folder/folder/folder"

HOST_NIC="eth0"
HOST_IP="x.x.x.x"
HOST_SUBNET="32"
HOST_GATEWAY="x.x.x.x"

MYSQL_USER="root"
MYSQL_PASSWORD=""

NEXTCLOUD_USER="nextcloud"
NEXTCLOUD_PASSWORD="nextcloud"





# =================================================================================================================================================================================================== #





# --- UPDATE and UPGRADE ---
sudo apt update
sudo apt upgrade -y
sudo apt install -y openssh-server ufw wget git unzip htop





# =================================================================================================================================================================================================== #





# --- Allow SSH on FIREWALL ---
#sudo ufw default deny incoming
#sudo ufw default deny outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2049/tcp
sudo ufw enable



# --- Setting up IP ---
sudo rm /etc/netplan/50-cloud-init.yaml
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/50-cloud-init.yaml -P /etc/netplan/
sudo sed -i 's/HOST_NIC/'${HOST_NIC}'/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_IP/'${HOST_IP}'/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_SUBNET/'${HOST_SUBNET}'/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_GATEWAY/'${HOST_GATEWAY}'/g' /etc/netplan/50-cloud-init.yaml
sudo netplan apply





# =================================================================================================================================================================================================== #





# --- Setting up NANO ---
sudo apt install -y nano
sudo rm /etc/nanorc
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/nanorc -P /etc/



# --- Setting up MOTD ---
sudo rm -rf /etc/legal
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news



# --- Setting up ZSH ---
sudo apt install -y zsh
echo "N exit" | sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm .zshrc
wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/.zshrc
wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/.p10k.zsh
chsh -s /bin/zsh



# --- Installing Avahi for mDNS ---
sudo apt install -y avahi-daemon





# =================================================================================================================================================================================================== #





# --- CONFIGURE NFS ---
sudo apt install -y nfs-common

sudo mkdir /mnt/NEXTCLOUD_LOGS
sudo mount ${NFS_IP}:${NFS_LOGS} /mnt/NEXTCLOUD_LOGS
echo "${NFS_IP}:${NFS_LOGS} /mnt/NEXTCLOUD_LOGS nfs defaults 0 0" | sudo tee -a /etc/fstab

sudo mkdir /mnt/NEXTCLOUD_DATA
sudo mount ${NFS_IP}:${NFS_DATA} /mnt/NEXTCLOUD_DATA
echo "${NFS_IP}:${NFS_DATA} /mnt/NEXTCLOUD_DATA nfs defaults 0 0" | sudo tee -a /etc/fstab



# --- CONFIGURE CACHE FOLDER ---
sudo mkdir /mnt/NEXTCLOUD_CACHE





# =================================================================================================================================================================================================== #





# --- NEXTCLOUD ---
sudo apt install -y apache2 php libapache2-mod-php php-fpm libapache2-mod-fcgid mariadb-server php-gd php-mysql php-curl php-xml php-mbstring php-zip php-intl php-bcmath php-gmp

PHP_VERSION=$(php -v | grep '[1-9]\.[1-9]' -o -m 1)
FPM_CONF=$(ls /etc/apache2/conf-available/ | grep -E 'php.+-fpm' | awk -F '.conf' '{print $1}')

sudo a2dismod php${PHP_VERSION}
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event
sudo a2enconf ${FPM_CONF}
sudo a2enmod proxy
sudo a2enmod proxy_fcgi
sudo a2enmod setenvif
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo a2enmod ssl
sudo a2enmod http2

sudo a2dissite 000-default.conf

sudo rm /etc/apache2/apache2.conf
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/apache2.conf -P /etc/apache2/

sudo rm /etc/php/${PHP_VERSION}/fpm/php.ini
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/php.ini -P /etc/php/${PHP_VERSION}/fpm/

sudo rm /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/www.conf -P /etc/php/${PHP_VERSION}/fpm/pool.d/

sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "CREATE USER '${NEXTCLOUD_USER}'@'localhost' identified by '${NEXTCLOUD_PASSWORD}';"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "GRANT ALL PRIVILEGES on nextcloud.* to '${NEXTCLOUD_USER}'@'localhost';"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "FLUSH PRIVILEGES;"

sudo wget https://download.nextcloud.com/server/releases/latest.zip -P /var/www/
sudo unzip /var/www/latest.zip -d /var/www/
sudo rm /var/www/latest.zip

sudo chown -R www-data:www-data /var/www/nextcloud
sudo chown -R www-data:www-data /mnt/NEXTCLOUD_DATA
sudo chown -R www-data:www-data /mnt/NEXTCLOUD_LOGS
sudo chown -R www-data:www-data /mnt/NEXTCLOUD_CACHE

sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/nextcloud.conf -P /etc/apache2/sites-available/
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/nextcloud_ssl.conf -P /etc/apache2/sites-available/

sudo a2ensite nextcloud.conf
sudo a2ensite nextcloud_ssl.conf
sudo service apache2 restart




# =================================================================================================================================================================================================== #





# --- MEMORY CACHING ---
sudo apt install -y php-apcu
sudo rm /etc/php/${PHP_VERSION}/mods-available/apcu.ini
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/apcu.ini -P /etc/php/${PHP_VERSION}/mods-available/
sudo service apache2 restart



sudo apt install -y redis-server php-redis
sudo phpenmod redis
sudo rm /etc/redis/redis.conf
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/redis.conf -P /etc/redis/
sudo systemctl restart redis
sudo usermod -a -G redis www-data



# sudo rm /var/www/nextcloud/config/config.php
# sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/config.php -P /var/www/nextcloud/config/






# =================================================================================================================================================================================================== #





# --- IMAGICK ---
sudo apt install -y php-imagick libmagickcore-6.q16-6-extra
sudo phpenmod imagick
sudo systemctl restart apache2
