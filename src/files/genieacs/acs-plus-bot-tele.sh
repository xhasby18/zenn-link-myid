lokal_ip=$(hostname -I | awk '{print $1}')
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${YELLOW}Apakah Anda ingin melanjutkan instalasi GenieACS? (y/n): ${RESET}"
read -p "> " konfirmasi
if [[ ! "$konfirmasi" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${RESET}"
    exit 1
fi

apt update 
apt install curl git openssh-sftp-server -y

echo -e "${YELLOW}Mengatur permit SSH${RESET}"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

echo -e "${YELLOW}Memulai instalasi GenieACS...${RESET}"
echo "Menginstal Node.js..."
curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt install -y nodejs
node -v

echo "Menginstal MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt update
apt install -y mongodb-org
systemctl start mongod.service
systemctl enable mongod

mongo --eval 'db.runCommand({ connectionStatus: 1 })'

echo "Menginstal GenieACS..."
npm install -g --unsafe-perm genieacs@1.2.7
useradd --system --no-create-home --user-group genieacs
mkdir -p /opt/genieacs/ext
chown genieacs:genieacs /opt/genieacs/ext

echo "Membuat file konfigurasi GenieACS..."
cat <<EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
EOF
chown genieacs:genieacs /opt/genieacs/genieacs.env
chmod 600 /opt/genieacs/genieacs.env
mkdir -p /var/log/genieacs
chown genieacs:genieacs /var/log/genieacs

echo "Membuat file unit systemd untuk GenieACS..."
cat <<EOF > /etc/systemd/system/genieacs-cwmp.service
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/systemd/system/genieacs-nbi.service
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/systemd/system/genieacs-fs.service
[Unit]
Description=GenieACS FS
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/systemd/system/genieacs-ui.service
[Unit]
Description=GenieACS UI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui

[Install]
WantedBy=default.target
EOF

echo "Membuat file konfigurasi logrotate untuk GenieACS..."
cat <<EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF

echo "Mengaktifkan dan memulai layanan GenieACS..."
systemctl daemon-reload
systemctl enable genieacs-cwmp
systemctl start genieacs-cwmp
systemctl enable genieacs-nbi
systemctl start genieacs-nbi
systemctl enable genieacs-fs
systemctl start genieacs-fs
systemctl enable genieacs-ui
systemctl start genieacs-ui

read -p "Lanjut Intall Python? (y/n): " konfirmasiLanjut
if [[ ! "$konfirmasiLanjut" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Instalasi GenieACS selesai!${RESET}"
    echo -e "${GREEN}Buka http://$lokal_ip:3000 di browser untuk akses UI GenieACS.${RESET}"
    exit 1
fi

cp /etc/apt/sources.list /etc/apt/sources.list.bak
rm /etc/apt/sources.list

cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free

deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian bullseye-updates main contrib non-free

deb http://deb.debian.org/debian bullseye-backports main contrib non-free
deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free

deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://security.debian.org/debian-security/ bullseye-security main contrib non-free
EOF

apt update
apt install python3 python3-pip -y

read -p "Lanjut Setup bot? (y/n): " konfirmasiBot
if [[ ! "$konfirmasiBot" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Instalasi GenieACS dan Python selesai!${RESET}"
    echo -e "${GREEN}Buka http://$lokal_ip:3000 di browser untuk akses UI GenieACS.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Masukkan token bot telegram:${RESET}"
read -p "> " TOKEN_BOT

git clone https://github.com/Nandaxy/telebot-acs
cd telebot-acs
pip install -r requirements.txt

#mengubah file config.py
# TELEGRAM_TOKEN = ""
# API_URL = "http://localhost:7557"
# SSIDKE = 1

sed -i "s|TELEGRAM_TOKEN = \"\"|TELEGRAM_TOKEN = \"$TOKEN_BOT\"|g" config.py

echo -e "${GREEN}Instalasi GenieACS selesai dan Bot telah di setup!${RESET}"
echo -e "${GREEN}Buka http://$lokal_ip:3000 di browser untuk akses UI GenieACS.${RESET}"
exit 1
