#!/usr/bin/bash

# Make sure a version of gazu is installed
sudo /opt/zou/zouenv/bin/pip3 install gazu

while read line;do

# 1) Get info for ever user in files/user.txt
first=$(echo $line | awk '{print $1}')
last=$(echo $line | awk '{print $2}')
email=$(echo $line | awk '{print $3}')
login=$(echo $line | awk '{print $4}')
value=$(echo $line | awk '{print $5}')

# 2) Ensure each user exists and update their values
/opt/zou/zouenv/bin/python - << EOF
import gazu

gazu.set_host('http://localhost/api')
gazu.log_in('$ADMIN_EMAIL', '$ADMIN_PASSWORD')

person = gazu.person.get_person_by_email('$email')
if not person:
    gazu.person.new_person(
      first_name='$first',
      last_name='$last',
      email='$email',
      desktop_login='$login',
    )
EOF

# 3) Update existing users with values from the text file
read -d '' SQL_QUERY << EOF
UPDATE person
SET first_name='$first', last_name='$last', desktop_login='$login', is_generated_from_ldap = $value
WHERE email = '$email';
EOF
PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USERNAME -d zoudb -c "$SQL_QUERY"

done <files/users.txt