Copy this for installation:
```
wget https://raw.githubusercontent.com/LoBrol/ubuntu-nextcloud/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```
Remember to change the variables

Useful commands:
```
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ theming:config disable-user-theming yes           # disable user theming
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ maintenance:repair                                # repair NextCloud installation
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ files:scan --all                                  # scan all file of all users
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ config:app:set files max_chunk_size --value 0     # disable the chunking of the file
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ config:system:set skeletondirectory               # disable default files when creating user
sudo -u www-data php --define apc.enable_cli=1 /var/www/nextcloud/occ maintenance:update:htaccess                       # update htaccess
```
