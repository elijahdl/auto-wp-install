#!/usr/bin/bash

# wordpress setup script
# elijah love november 2017

# Check if root
if [[ $EUID -ne 0 ]]; then
	echo "Run me as root, please"
	exit 1
fi

# Get user variables
echo "Wordpress database name:"
read wpDatabaseName
echo "Wordpress database user:"
read wpDatabaseUser
echo "Wordpress database user password:"
read wpDatabasePassword


# Install required packages
yum -y install mariadb-server mariadb httpd php php-mysql php-gd php-ldap \
php-odbc php-pear php-xml php-xmlrpc php-mbstring php-soap curl curl-devel



# Start and enable systemd services
systemctl start mariadb.service
systemctl enable mariadb.service
systemctl start httpd.service
systemctl enable httpd.service

# Set up mariadb
mysql_secure_installation

# Adjust firewall rules
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

# Set up wordpress database
mysql -u root -p -e "CREATE DATABASE $wpDatabaseName; CREATE USER $wpDatabaseUser@localhost; SET PASSWORD FOR $wpDatabaseUser= PASSWORD('$wpDatabasePassword@localhost'); GRANT ALL PRIVILEGES ON $wpDatabaseName.* TO $wpDatabaseUser@localhost IDENTIFIED BY '$wpDatabasePassword'; FLUSH PRIVILEGES; "


# Download wordpress
mkdir /tmp
cd /tmp
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
cd /tmp/wordpress

# Prepare wp-config.php
sed -e "s/database_name_here/$wpDatabaseName/" \
-e "s/username_here/$wpDatabaseUser/" \
-e "s/password_here/$wpDatabasePassword/" \
< wp-config-sample.php > wp-config.php

# Install wordpress
cp -r /tmp/wordpress/* /var/www/html/
service httpd restart

echo "Wordpress is (hopefully) installed! Visit $(hostname)/wp-admin/install.php"


