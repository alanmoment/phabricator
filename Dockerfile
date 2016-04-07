#
# Docker image for running https://github.com/phacility/phabricator
#

FROM    debian:jessie
MAINTAINER  Yvonnick Esnault <yvonnick@esnau.lt>

ENV DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true

# TODO: review this dependency list
RUN     apt-get update && apt-get install -y \
            telnet \
            vim \
	        git \
            apache2 \
            curl \
            libapache2-mod-php5 \
            libmysqlclient18 \
            mercurial \
            mysql-client \
            php-apc \
            php5 \
            php5-apcu \
            php5-cli \
            php5-curl \
            php5-gd \
            php5-json \
            php5-ldap \
            php5-mysql \
            python-pygments \
            sendmail \
            subversion \
            wget \ 
            tar \
            sudo \
            build-essential \ 
            nodejs \
            npm \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
# For some reason phabricator doesn't have tagged releases. To support
# repeatable builds use the latest SHA
# ADD     download.sh /opt/download.sh
# RUN     bash download.sh phabricator 79f2e81f38
# RUN     bash download.sh arcanist    c304c4e045
# RUN     bash download.sh libphutil   55f554b618

# Because the old version not support Scurm flow
# Version 
# phabricator b1f3e02d82133319afe999df4855634b20f0b09e (Sat, Jan 23)
# arcanist b87138356a9c71ad5e08eaa05399d0233529bc71 (Sat, Jan 16)
# phutil f43291e99d36045bc459e5133454c0d8fd8768ea (Fri, Jan 22)
RUN     git clone https://github.com/phacility/phabricator.git
RUN     cd phabricator && git checkout -b local b1f3e02 && cd ..

RUN     git clone https://github.com/phacility/arcanist.git
RUN     cd arcanist && git checkout -b local b871383 && cd ..

RUN     git clone https://github.com/phacility/libphutil.git
RUN     cd libphutil && git checkout -b local f43291e && cd ..

# Scrum for Phabricator
# Version 
# sprint ffd2bce75f68ce9b6c030e3ee27e36163c3ecaf2 (Tue, Jan 19)
RUN     mkdir -p /opt/libext/sprint
RUN     git clone https://github.com/wikimedia/phabricator-extensions-Sprint.git /opt/libext/sprint
RUN     cd /opt/libext/sprint && git checkout -b local ffd2bce && cd ../../
RUN     ln -s /opt/libext/sprint/rsrc/webroot-static /opt/phabricator/webroot/rsrc/sprint

ADD     backup.sh /opt/backup.sh
RUN     mkdir -p /opt/backup/repo
RUN     mkdir -p /opt/backup/storage
RUN     mkdir -p /opt/backup/mysql
RUN     chmod 777 /opt/backup/storage
# VOLUME  ["/opt/backup/storage"]
# VOLUME  ["/opt/backup/repo"]

# Setup apache
RUN     a2enmod rewrite
ADD     phabricator.conf /etc/apache2/sites-available/phabricator.conf
RUN     ln -s /etc/apache2/sites-available/phabricator.conf \
            /etc/apache2/sites-enabled/phabricator.conf && \
        rm -f /etc/apache2/sites-enabled/000-default.conf

# install PHPExcel for Maniphest
RUN     git clone https://github.com/PHPOffice/PHPExcel.git /usr/share/php/PHPExcel
RUN     sed -e 's/\;include_path = "\.\:\/usr\/share\/php"/include_path = "\.\:\/usr\/share\/php\:\/usr\/share\/php\/PHPExcel\/Classes"/' \
          -i /etc/php5/apache2/php.ini

# Setup phabricator
RUN     mkdir -p /opt/phabricator/conf/local /var/repo
ADD     local.json /opt/phabricator/conf/local/local.json
RUN     sed -e 's/post_max_size = 8M/post_max_size = 32M/' \
          -e 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' \
          -i /etc/php5/apache2/php.ini
RUN     ln -s /usr/lib/git-core/git-http-backend /opt/phabricator/support/bin
RUN     /opt/phabricator/bin/config set phd.user "root"
RUN     echo "www-data ALL=(ALL) SETENV: NOPASSWD: /opt/phabricator/support/bin/git-http-backend" >> /etc/sudoers

EXPOSE  80
ADD     entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD     ["start-server"]
