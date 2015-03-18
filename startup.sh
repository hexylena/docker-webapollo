#!/bin/bash

export PGUSER=web_apollo_users_admin
export PGPASSWORD=password
export WEBAPOLLO_USER=web_apollo_admin
export WEBAPOLLO_PASSWORD=password
export WEBAPOLLO_DATABASE=web_apollo_users
export ORGANISM="Pythium ultimum"
export JBROWSE_DATA_DIR=/opt/apollo/jbrowse/data
export WEBAPOLLO_DATA_DIR=/opt/apollo/annotations
export WEBAPOLLO_ROOT=/webapollo/
export JBROWSE_DIR=$WEBAPOLLO_ROOT/jbrowse-download/

psql -U postgres -h $DB_PORT_5432_TCP_ADDR -c "CREATE USER $PGUSER NOCREATEROLE CREATEDB NOINHERIT LOGIN NOSUPERUSER ENCRYPTED PASSWORD '$WEBAPOLLO_PASSWORD'"
psql -U postgres -h $DB_PORT_5432_TCP_ADDR -c "CREATE DATABASE $WEBAPOLLO_DATABASE ENCODING='UTF-8' OWNER=$PGUSER"


CONFIG_FILE=$CATALINA_HOME/webapps/ROOT/config/config.properties

sed -i "s|database.url=.*|database.url=jdbc:postgresql://$DB_PORT_5432_TCP_ADDR:5432/$WEBAPOLLO_DATABASE|g" $CONFIG_FILE
sed -i "s|database.username=.*|database.username=$PGUSER|g" $CONFIG_FILE
sed -i "s|database.password=.*|database.password=$PGPASSWORD|g" $CONFIG_FILE
sed -i "s|organism=.*|organism=$ORGANISM|g" $CONFIG_FILE


# TODO wait for endpoint to be alive

psql -U $PGUSER $WEBAPOLLO_DATABASE -h $DB_PORT_5432_TCP_ADDR < $WEBAPOLLO_ROOT/tools/user/user_database_postgresql.sql

mkdir -p /opt/apollo/annotations /opt/apollo/jbrowse/data/
# Need JBlib.pm
export PERL5LIB=/webapollo/jbrowse-download/src/perl5
$WEBAPOLLO_ROOT/tools/user/add_user.pl -D $WEBAPOLLO_DATABASE -U $PGUSER -P $PGPASSWORD -u $WEBAPOLLO_USER -p $WEBAPOLLO_PASSWORD -H $DB_PORT_5432_TCP_ADDR

/bin/process.sh

# Run tomcat and tail logs
cd $CATALINA_HOME && ./bin/catalina.sh run
