#!/bin/bash



NFS_IP="x.x.x.x"
NFS_LOGS="folder/folder/folder"
NFS_DATA="folder/folder/folder"

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
sudo apt install -y openssh-server nano ufw curl wget git unzip zsh lm-sensors





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
sudo sed -i 's/HOST_IP/'${HOST_IP}'/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_SUBNET/'${HOST_SUBNET}'/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_GATEWAY/'${HOST_GATEWAY}'/g' /etc/netplan/50-cloud-init.yaml
sudo netplan apply





# =================================================================================================================================================================================================== #





# --- Setting up NANO ---
sudo rm /etc/nanorc
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/nanorc -P /etc/



# --- Setting up MOTD ---
sudo rm -rf /etc/legal
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news



# --- Setting up SENSORS ---
echo "Y Y Y" | sudo sensors-detect



# --- Setting up ZSH ---
echo "N exit" | sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm .zshrc
wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/.zshrc
wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/.p10k.zsh
chsh -s /bin/zsh





# =================================================================================================================================================================================================== #





# --- CONFIGURE NFS ---
sudo apt install -y nfs-common
sudo mkdir /mnt/NEXTCLOUD_LOGS
sudo mount ${NFS_IP}:${NFS_LOGS} /mnt/NEXTCLOUD_LOGS
echo "${NFS_IP}:${NFS_LOGS} /mnt/NEXTCLOUD_LOGS nfs defaults 0 0" | sudo tee -a /etc/fstab
sudo mkdir /mnt/NEXTCLOUD_DATA
sudo mount ${NFS_IP}:${NFS_DATA} /mnt/NEXTCLOUD_DATA
echo "${NFS_IP}:${NFS_DATA} /mnt/NEXTCLOUD_DATA nfs defaults 0 0" | sudo tee -a /etc/fstab





# =================================================================================================================================================================================================== #





# --- NEXTCLOUD ---
sudo apt install -y apache2 php libapache2-mod-php mariadb-server
sudo apt install -y php-fpm libapache2-mod-fcgid php-gd php-mysql php-curl php-xml php-mbstring php-zip php-intl

FPM_CONF=$(ls /etc/apache2/conf-available/ | grep -E 'php.+-fpm' | awk -F '.conf' '{print $1}')

sudo a2dismod mpm_prefork
sudo a2enmod mpm_event
sudo a2enconf ${FPM_CONF}
sudo a2enmod proxy
sudo a2enmod proxy_fcgi
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo a2enmod ssl

# sudo systemctl restart apache2

PHP_VERSION=$(php -v | grep '[1-9]\.[1-9]' -o -m 1)
sudo sed -i 's/memory_limit = 128M/memory_limit = 6G/g' /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i 's/output_buffering = 4096/output_buffering = 0/g' /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64G/g' /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i 's/post_max_size = 8M/post_max_size = 64G/g' /etc/php/${PHP_VERSION}/fpm/php.ini

# sudo systemctl restart apache2

sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "CREATE USER '${NEXTCLOUD_USER}'@'localhost' identified by '${NEXTCLOUD_PASSWORD}';"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "GRANT ALL PRIVILEGES on nextcloud.* to '${NEXTCLOUD_USER}'@'localhost';"
sudo mysql --user ${MYSQL_USER} --password="${MYSQL_PASSWORD}" -e "FLUSH PRIVILEGES;"

sudo wget https://download.nextcloud.com/server/releases/latest.zip -P /var/www/
sudo unzip /var/www/latest.zip -d /var/www/
sudo rm /var/www/latest.zip

sudo chown -R www-data:www-data /var/www/nextcloud
sudo chown -R www-data:www-data /mnt/NEXTCLOUD_DATA
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/nextcloud.conf -P /etc/apache2/sites-available/
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/nextcloud_ssl.conf -P /etc/apache2/sites-available/

sudo rm /etc/apache2/apache2.conf
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/apache2.conf -P /etc/apache2/

sudo a2dissite 000-default.conf
sudo a2ensite nextcloud.conf
sudo a2ensite nextcloud_ssl.conf
sudo service apache2 restart




# =================================================================================================================================================================================================== #





# --- MEMORY CACHING ---
sudo apt install -y php-apcu
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/apcu.ini -P /etc/php/${PHP_VERSION}/mods-available/
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ maintenance:repair
sudo service apache2 restart

sudo apt install -y redis-server
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/redis.conf -P /etc/redis/
sudo systemctl restart redis
sudo usermod -a -G redis www-data

sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/file_to_be_copied/config.php -P /var/www/nextcloud/config/
