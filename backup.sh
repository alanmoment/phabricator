#!/bin/sh

TIMESTAMP=$(date +%s)
DATE=$(date '+%Y_%m_%d_%H_%M_%S')
/opt/phabricator/bin/storage dump | gzip > /opt/backup/mysql/${DATE}.sql.gz

tar -zcvf /opt/backup/repo/${DATE}.tar.gz /var/repo/

cp -a /opt/phabricator/conf/local/local.json /opt/backup/repo/${DATE}.json
# exec bash -c "/opt/phabricator/bin/files migrate --all --engine local-disk";