FROM php:7.3-apache

# MSSQL
RUN apt-get update -yqq \
    && apt-get install -y make htop apt-transport-https gnupg2 wget \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update -yqq \
    && ACCEPT_EULA=Y apt-get install -yqq msodbcsql17=17.3.1.1-1 mssql-tools=17.3.0.1-1 unixodbc-dev \
    && wget http://security-cdn.debian.org/debian-security/pool/updates/main/o/openssl1.0/libssl1.0.2_1.0.2u-1~deb9u1_amd64.deb \
    && dpkg -i libssl1.0.2_1.0.2u-1~deb9u1_amd64.deb

# Composer
COPY composer.phar /usr/local/bin/composer
RUN chmod 0777 /usr/local/bin/composer

# Install pdo_sqlsrv and sqlsrv from PECL.
RUN wget http://pecl.php.net/get/sqlsrv-5.6.1.tgz \
    && pear install sqlsrv-5.6.1.tgz \
    && wget http://pecl.php.net/get/pdo_sqlsrv-5.6.1.tgz \
    && pear install pdo_sqlsrv-5.6.1.tgz \
    && docker-php-ext-enable pdo_sqlsrv sqlsrv \
    && php -m | grep -q 'pdo_sqlsrv' \
    && php -m | grep -q 'sqlsrv'

# PHP
RUN apt-get install -y git zip libmcrypt-dev openssh-client \
    libpq-dev libmemcached-dev \
    libxml2-dev libpng-dev g++ make autoconf libzip-dev

# Zip
RUN wget http://pecl.php.net/get/zip-1.17.1.tgz \
    && pear install zip-1.17.1.tgz \
    && docker-php-ext-enable zip \
    && php -m | grep -q 'zip'

# Memcached
RUN wget http://pecl.php.net/get/memcached-3.1.5.tgz \
    && pear install memcached-3.1.5.tgz \
    && docker-php-ext-enable memcached \
    && php -m | grep -q 'memcached'

# Xdebug
RUN wget http://pecl.php.net/get/xdebug-2.9.0.tgz \
    && pear install xdebug-2.9.0.tgz \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_port=9001" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_connect_back=0" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.idekey=mertblog.net" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_host=docker.for.mac.localhost" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && php -m | grep -q 'xdebug'

# Copy apache vhost file to proxy php requests to php-fpm container
COPY localhost.conf /usr/local/apache2/conf/localhost.conf
RUN echo "Include /usr/local/apache2/conf/localhost.conf" \
    >> /usr/local/apache2/conf/httpd.conf

RUN a2enmod rewrite
ADD . /var/www/html

# Clean
RUN rm -rf /tmp/*
