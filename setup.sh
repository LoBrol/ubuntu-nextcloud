#!/bin/bash



NFS_IP="x.x.x.x"
NFS_PATH="folder/folder/folder"

HOST_IP="x.x.x.x"
HOST_SUBNET="32"
HOST_GATEWAY="x.x.x.x"




# --- UPDATE and UPGRADE ---
sudo apt update
sudo apt upgrade -y
sudo apt install -y openssh-server nano ufw tee curl wget git df zsh neofetch lm-sensors



# --- Allow SSH on FIREWALL ---
ufw default deny incoming
ufw default deny outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 2049/tcp



# --- Setting up IP ---
sudo rm /etc/netplan/50-cloud-init.yaml
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu_docker/main/file_to_be_copied/50-cloud-init.yaml -P /etc/netplan/
sudo sed -i 's/HOST_IP/${HOST_IP}/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_SUBNET/${HOST_SUBNET}/g' /etc/netplan/50-cloud-init.yaml
sudo sed -i 's/HOST_GATEWAY/${HOST_GATEWAY}/g' /etc/netplan/50-cloud-init.yaml



# --- Setting up NANO ---
sudo rm /etc/nanorc
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu_docker/main/file_to_be_copied/nanorc -P /etc/






# --- Setting up MOTD ---
sudo rm -rf /etc/legal
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news
sudo wget https://raw.githubusercontent.com/LoBrol/ubuntu_docker/main/file_to_be_copied/20-neofetch -P /etc/update-motd.d/
sudo chmod +x /etc/update-motd.d/20-neofetch



# --- Setting up SENSORS ---
echo "Y Y Y" | sudo sensors-detect



# --- Setting up ZSH ---
echo "N exit" | sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm .zshrc
wget https://raw.githubusercontent.com/LoBrol/ubuntu_docker/main/file_to_be_copied/.zshrc
wget https://raw.githubusercontent.com/LoBrol/ubuntu_docker/main/file_to_be_copied/.p10k.zsh
chsh -s /bin/zsh






# --- CONFIGURE NFS ---
sudo apt install -y nfs-common nfs-utils
sudo mkdir /mnt/NFS
sudo mount ${NFS_IP}:${NFS_PATH} /mnt/NFS
echo "${NFS_IP}:${NFS_PATH}        /mnt/NFS        nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab






# --- NEXTCLOUD ---
sudo apt install -y apache2 php libapache2-mod-php php-gd php-mysql php-curl php-xml php-mbstring php-zip php-intl mariadb-server
