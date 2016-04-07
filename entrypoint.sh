#!/bin/sh

if [ -z "${LOCAL_JSON}" ]; then
  [ -z "${MYSQL_HOST}" ] && export MYSQL_HOST="database"
  [ -z "${MYSQL_USER}" ] && export MYSQL_USER="admin"
  [ -z "${MYSQL_PASS}" ] && export MYSQL_PASS="admin"

  # Patching the settings file.
  sed -e "s/{{MYSQL_HOST}}/${MYSQL_HOST}/g" \
    -e "s/{{MYSQL_USER}}/${MYSQL_USER}/g" \
    -e "s/{{MYSQL_PASS}}/${MYSQL_PASS}/g" \
    -i /opt/phabricator/conf/local/local.json
else
  echo "${LOCAL_JSON}" > /opt/phabricator/conf/local/local.json
fi

if [ "${1}" = "start-server" ]; then
  exec bash -c "/opt/phabricator/bin/storage upgrade --force; /opt/phabricator/bin/phd start; source /etc/apache2/envvars; /usr/sbin/apache2 -DFOREGROUND"
else
  exec $@
fi

if [ -d "/opt/backup" ]; then
else
  exec bash -c "mkdir -p /opt/backup/storage"
  exec bash -c "mkdir -p /opt/backup/repo"
  exec bash -c "mkdir -p /opt/backup/mysql"
  exec bash -c "chmod 777 -R /opt/backup/storage"
fi