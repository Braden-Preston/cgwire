#!/usr/bin/bash

# # Warn the hell out of the user, because this is a highly dangerous operation
# echo -e "\n\033[0;31mDANGER: Are you sure you want to DESTROY the Kitsu installation?\033[0m [Y/n]"
# echo -e "\nThe following will be WIPED OUT:"
# echo -e "    - Docker instances, their volumes, and networks"
# echo -e "    - Postgres password, zou database, and ALL data"
# echo -e "    - Services like Redis and Nginx will be disabled"
# echo -e "    - ALL attachments, indexes, and backup"

# # Read answer and only continue if valid
# read answer
# if [ "$answer" != "${answer#[Yy]}" ]; then :; else return; fi

# # Set environment variables from .env file
# export $(grep -v '^#' .env | xargs)



# Kick all connections off by restarting services
sudo docker-compose down
sudo docker-compose up -d

# Destroy existing database and all data
db_exists=$(PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -lqt | cut -d \| -f 1 | grep -w $DB_DATABASE)
if [ $db_exists ]; then
  PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -c "drop database $DB_DATABASE;" 
fi