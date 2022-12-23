#!/usr/bin/bash

# Store current directory
CWD=$PWD

echo -e "\nSet environment variables from .env file..."
export $(grep -v '^#' .env | xargs)

echo -e "\nGet FQDN for machine"
FQDN=$(hostname --fqdn)

echo -e "\nEnsure system packages..."
# sudo apt -y install postgresql-client
# sudo apt -y install python3 python3-pip
# sudo apt -y install ffmpeg nginx git

echo -e "\nEnsure Zou user..."
sudo deluser zou
sudo useradd --home /opt/zou zou
sudo mkdir -p /opt/zou

echo -e "\nInstall Zou and its dependencies..."
sudo pip3 install virtualenv
sudo virtualenv /opt/zou/zouenv
# Install local Zou repo in editable mode
sudo /opt/zou/zouenv/bin/pip3 install -e ./zou

echo -e "\nInstall Kitsu and its dependencies..."
cd kitsu
# npm install
# npm run build
cd $CWD
sudo mkdir -p /opt/kitsu/dist
sudo rm -rf /opt/kitsu/dist
sudo cp -R kitsu/dist /opt/kitsu/
echo -e "\n/opt/kitsu/dist" # DEBUG
ll /opt/kitsu/dist # DEBUG

echo -e "\nCreate Zou controlled folders..."
sudo mkdir -p /opt/zou/tmp
sudo mkdir -p /opt/zou/logs
sudo mkdir -p /opt/zou/backups
sudo mkdir -p /opt/zou/indexes
sudo mkdir -p /opt/zou/previews
sudo chown -R zou:www-data /opt/zou

echo -e "\nBootstrap PostgreSQL and Reddis with Docker..."
sudo docker-compose up -d

echo -e "\nCreate a new database for Zou if it does not exist..."
db_exists=$(PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -lqt | cut -d \| -f 1 | grep -w $DB_DATABASE)
if [ -z $db_exists ]; then
  echo -e "\nCreating database and applying migrations..."
  PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -c "create database $DB_DATABASE;"
  PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -d postgres -c "alter user postgres with password '$DB_PASSWORD';"
  sudo -u zou DB_PASSWORD=$DB_PASSWORD /opt/zou/zouenv/bin/zou init-db
  sudo -u zou DB_PASSWORD=$DB_PASSWORD /opt/zou/zouenv/bin/zou init-data
  sudo -u zou DB_PASSWORD=$DB_PASSWORD /opt/zou/zouenv/bin/zou create-admin $ADMIN_EMAIL --password $ADMIN_PASSWORD
else
  echo "DB already exists"
  # PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -c "drop database $DB_DATABASE;" 
fi

echo -e "\nEvaluate variables in config files and save results..."
mkdir -p files/gen
srv_files="files/*.service"
for path in $srv_files; do
  name=${path##*/}
  envsubst < $path > files/gen/$name
done

echo -e "\nConfigure Gunicorn..."
sudo mkdir -p /etc/zou
sudo cp files/gunicorn.conf /etc/zou/gunicorn.conf
sudo cp files/gunicorn-events.conf /etc/zou/gunicorn-events.conf
echo -e "\n/etc/zou" # DEBUG
ll /etc/zou | grep gunicorn # DEBUG

sudo cp files/gen/zou.service /etc/systemd/system/zou.service
sudo cp files/gen/zou-events.service /etc/systemd/system/zou-events.service
echo -e "\n/etc/systemd/system" # DEBUG
ll /etc/systemd/system/ | grep zou # DEBUG

echo -e "\nConfigure Nginx..."
sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-available/zou
sudo cp files/zou.nginx /etc/nginx/sites-available/zou
sudo ln -s /etc/nginx/sites-available/zou /etc/nginx/sites-enabled
echo -e "\n/etc/nginx/sites-enabled" # DEBUG
ll /etc/nginx/sites-enabled | grep zou # DEBUG
echo -e "\nHost Address: $FQDN"

echo -e "\nCopy Radius configuration"
sudo cp files/pam_radius.conf /etc/pam_radius.conf
echo -e "\n/etc/pam_radius.conf" 
ll /etc/pam_radius.conf | grep pam_radius

echo -e "\nReload all services..."
# sudo systemctl stop zou
# sudo systemctl stop zou-events
# sudo systemctl stop nginx
# sudo systemctl enable zou
# sudo systemctl enable zou-events
# sudo systemctl enable nginx
sudo systemctl daemon-reload
sudo systemctl restart zou
sudo systemctl restart zou-events
sudo systemctl restart nginx

echo -e "\nEnable MFA for users"
# ./zou-make-users.sh
