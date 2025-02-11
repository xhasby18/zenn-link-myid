#!/bin/bash

# Update paket-paket dan pastikan wget serta unzip tersedia
echo "Updating system and installing wget, unzip..."
apt update -y
apt install -y wget unzip

# Pindah ke direktori web server
echo "Navigating to /var/www/html..."
cd /var/www/html

# Unduh file WordPress
echo "Downloading WordPress..."
wget http://172.16.90.2/unduh/wordpress.zip

# Ekstrak file ZIP WordPress
echo "Extracting WordPress..."
unzip wordpress.zip

# Ubah izin folder WordPress
echo "Setting permissions for WordPress..."
chmod -R 777 wordpress

# Informasi untuk pengguna mengenai database dan user
echo "Please enter the following details to create the WordPress database and user:"
echo "Enter MySQL root password: "
read -s ROOT_PASSWORD

# Masuk ke MySQL dan buat database serta pengguna
echo "Creating database and user for WordPress..."
mysql -u root -p$ROOT_PASSWORD -e "CREATE DATABASE wordpress;"
mysql -u root -p$ROOT_PASSWORD -e "CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'password';"
mysql -u root -p$ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';"
mysql -u root -p$ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# Konfirmasi pembuatan database dan user
echo "Database and user for WordPress created successfully."

# Petunjuk untuk konfigurasi WordPress melalui browser
echo "Please continue the WordPress setup by completing the setup in your browser."
echo "Visit your website and follow the WordPress installation wizard."
echo "Use the following details to configure the database during installation:"
echo "Database Name: wordpress"
echo "Username: wp_user"
echo "Password: password"

# Tampilkan status direktori
ls /var/www/html/wordpress

# Menampilkan IP server
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Your server's IP address is: $IP_ADDRESS"

# Menampilkan sumber skrip
echo "This script was sourced from: Bangkomar232@gmail.com"

echo "WordPress setup complete!"
