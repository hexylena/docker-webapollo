#!/bin/bash
$CATALINA_HOME/bin/catalina.sh start
/etc/init.d/postgresql start
sudo -u postgres createuser --no-superuser --createdb --no-createrole web_apollo_users_admin
sudo -u postgres psql -c "ALTER USER web_apollo_users_admin WITH ENCRYPTED PASSWORD 'password'"
sudo -u postgres createdb -O web_apollo_users_admin web_apollo_users
cd $WEB_APOLLO_DIR/tools/user && psql -U web_apollo_users_admin web_apollo_users < user_database_postgresql.sql
cd $WEB_APOLLO_DIR/tools/user && ./add_user.pl -D web_apollo_users -U web_apollo_users_admin -P password -u web_apollo_admin -p web_apollo_admin
# Ready to go!
