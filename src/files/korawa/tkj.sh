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

# Instalasi MySQL dan lakukan konfigurasi keamanan
echo "Securing MySQL installation..."
mysql_secure_installation

# Membuat database dan user untuk WordPress di MySQL
echo "Creating WordPress database and user..."
mysql -u root -p <<EOF
CREATE DATABASE wordpress;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Informasikan pengguna untuk melanjutkan konfigurasi WordPress
echo "Database and user for WordPress created successfully."
echo "Please continue with the WordPress installation by completing the setup in your browser."
echo "Visit your website and follow the WordPress installation wizard."

# Tampilkan status direktori
ls /var/www/html/wordpress

echo "WordPress setup complete!"
