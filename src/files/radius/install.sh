#!/bin/bash

install_otomatis() {
    echo "Melakukan instalasi FreeRadius..."

    read -sp "Masukkan password MySQL untuk phpMyAdmin: " mysql_password
    echo

    read -sp "Konfirmasi password MySQL: " mysql_password_confirm
    echo

    if [[ "$mysql_password" != "$mysql_password_confirm" ]]; then
        echo -e "\033[31mPassword yang dimasukkan tidak cocok, silakan coba lagi.\033[0m"
        exit 1
    fi

    apt update
    apt install curl mariadb-server apache2 php -y
   
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password $mysql_password" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password $mysql_password" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password $mysql_password" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

    apt install phpmyadmin -y

    mysql -u root -p$mysql_password <<MYSQL_SCRIPT
    SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$mysql_password');
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
    FLUSH PRIVILEGES;
MYSQL_SCRIPT

    systemctl restart apache2

    echo "Menambahkan repository untuk FreeRADIUS..."

    install -d -o root -g root -m 0755 /etc/apt/keyrings
    curl -s 'https://packages.networkradius.com/pgp/packages%40networkradius.com' | \
        tee /etc/apt/keyrings/packages.networkradius.com.asc > /dev/null

    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.networkradius.com.asc] http://packages.networkradius.com/freeradius-3.2/debian/bullseye bullseye main" | \
        tee /etc/apt/sources.list.d/networkradius.list > /dev/null

    apt-get update

    apt-get -y install freeradius freeradius-mysql freeradius-utils

    mysql -uroot -p$mysql_password <<MYSQL_SCRIPT
    CREATE DATABASE radius;
    GRANT ALL ON radius.* TO 'radius'@'localhost' IDENTIFIED BY '$mysql_password';
    FLUSH PRIVILEGES;
MYSQL_SCRIPT

    mysql -u root -p$mysql_password radius < /etc/freeradius/mods-config/sql/main/mysql/schema.sql

    ln -s /etc/freeradius/mods-available/sql /etc/freeradius/mods-enabled/

    echo "Mengedit konfigurasi SQL pada FreeRADIUS..."

    #cp /etc/freeradius/mods-available/sql /etc/freeradius/mods-available/sql.bak
   
    sed -i '
        s/dialect = "sqlite"/dialect = "mysql"/g;
        /driver = "rlm_sql_null"/ {
            s/^/#/
            n
            s/^#//
        };
        s/^\s*#\s*server = "localhost"/        server = "localhost"/g;
        s/^\s*#\s*port = 3306/        port = 3306/g;
        s/^\s*#\s*login = "radius"/        login = "root"/g;
        s/^\s*#\s*password = "radpass"/        password = "'"$mysql_password"'"/g;
        s/^\s*#\s*read_clients = yes/        read_clients = yes/g;
    ' /etc/freeradius/mods-available/sql

    #ln -sf /etc/freeradius/mods-available/sql /etc/freeradius/mods-enabled/

    echo "Menonaktifkan konfigurasi TLS..."

    sed -i 's/ca_file = "/#ca_file = /' /etc/freeradius/mods-enabled/sql
    sed -i 's/ca_path = "/#ca_path = /' /etc/freeradius/mods-enabled/sql
    sed -i 's/certificate_file = "/#certificate_file = /' /etc/freeradius/mods-enabled/sql
    sed -i 's/private_key_file = "/#private_key_file = /' /etc/freeradius/mods-enabled/sql
    sed -i 's/cipher = "/#cipher = /' /etc/freeradius/mods-enabled/sql
    sed -i 's/tls_required = yes/#tls_required = yes/' /etc/freeradius/mods-enabled/sql
    sed -i 's/tls_check_cert = no/#tls_check_cert = no/' /etc/freeradius/mods-enabled/sql
    sed -i 's/tls_check_cert_cn = no/#tls_check_cert_cn = no/' /etc/freeradius/mods-enabled/sql

    echo "Konfigurasi FreeRADIUS selesai."
}

koneksi_router() {
    echo "Apakah Anda ingin mengkoneksikan Router Anda ke FreeRADIUS? (y/n) "
    read koneksi

    if [[ "$koneksi" == "y" || "$koneksi" == "Y" ]]; then

        read -p "Masukkan alamat IP router Anda: " router_ip
        read -p "Masukan Secret Key router Anda: " router_secret

        mysql -uroot -p$mysql_password -e "USE radius; 
        INSERT INTO nas (id, nasname, shortname, type, ports, secret, server, community, description) 
        VALUES (NULL, '$router_ip', NULL, 'other', NULL, '$router_secret', NULL, NULL, 'RADIUS Client');"

        echo -e "\033[32mRouter dengan IP $router_ip telah ditambahkan ke Database.\033[0m"

        echo "Apakah Anda ingin membuat user hotspot? (y/n)"
        read user_hotspot

        while [[ "$user_hotspot" != "y" && "$user_hotspot" != "Y" && "$user_hotspot" != "n" && "$user_hotspot" != "N" ]]; do
            echo "Apakah Anda ingin membuat user hotspot? (y/n)"
            read user_hotspot
        done

        if [[ "$user_hotspot" == "y" || "$user_hotspot" == "Y" ]]; then
            read -p "Masukkan Username untuk user hotspot: " username
            read -p "Masukkan Password untuk user hotspot: " password
            echo

            mysql -uroot -p$mysql_password -e "USE radius; 
            INSERT INTO radcheck (id, UserName, Attribute, op, Value) 
            VALUES (NULL, '$username', 'Cleartext-Password', ':=', '$password');"

            echo "User hotspot '$username' telah berhasil dibuat dengan password '$password'."
            echo -e "\033[32mInstalasi FreeRADIUS Selesai.\033[0m"
            echo -e "\033[32mTerima kasih telah menggunakan skrip ini.\033[0m"
            exit 0
        else
            echo -e "\033[32mInstalasi FreeRADIUS Selesai.\033[0m"
            echo -e "\033[32mTerima kasih telah menggunakan skrip ini.\033[0m"
        fi

    elif [[ "$koneksi" == "n" || "$koneksi" == "N" ]]; then
        echo -e "\033[32mInstalasi FreeRADIUS Selesai.\033[0m"
        echo -e "\033[32mTerima kasih telah menggunakan skrip ini.\033[0m"
    else
        echo -e "\033[31mInput tidak valid, silakan coba lagi.\033[0m"
        koneksi_router
    fi

}

main_menu() {
    echo -e "\033[32mSelamat datang di skrip instalasi FreeRADIUS.\033[0m"
    echo -e "\033[33mPilih Menu :\033[0m"
    echo "1) Instal otomatis"
    echo "2) Aktifkan mode debuging"
    echo "3) Jalankan Service FreeRADIUS"
    echo "4) Keluar"

    read -p "Masukkan pilihan Anda: " pilihan

    case $pilihan in
        1)
            install_otomatis
            koneksi_router
            ;;
        2) 
            echo -e "\033[33mAktifkan mode debuging...\033[0m" 
            service freeradius stop
            freeradius -X
            ;;
        3)
            echo -e "\033[33mJalankan Service FreeRADIUS...\033[0m"
            service freeradius restart
            service freeradius status
            ;;
        4)
            echo "Keluar dari skrip."
            echo "Terima kasih telah menggunakan skrip ini."
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid. Keluar dari skrip."
            exit 1
            ;;
    esac
}

main_menu
