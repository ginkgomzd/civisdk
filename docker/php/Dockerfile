ARG PHP_VERSION=7.3

FROM php:${PHP_VERSION}-apache

# Install apt packages
#
# ...required by php extensions:
# * gd: libpng-dev, libjpeg62-turbo-dev
# * imagick: libmagickwand-dev
# * imap: libc-client-dev, libkrb5-dev
# * intl: libicu-dev
# * soap: libxml2-dev
# * zip: libzip-dev
#
# Other Utilities
# * iproute2 (required to get host ip from container)
# * msmtp-mta (for routing mail to maildev)

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  iproute2 \
  libc-client-dev \
  libicu-dev \
  libjpeg62-turbo-dev \
  libkrb5-dev \
  libmagickwand-dev \
  libpng-dev \
  libxml2-dev \
  libzip-dev \
  msmtp-mta \
  && rm -r /var/lib/apt/lists/*

# Install php extensions (curl, json, mbstring, openssl, posix, phar
# are installed already and don't need to be specified here)
RUN docker-php-ext-install bcmath \
  && docker-php-ext-configure gd ${PHP_CONFIGURE_GD_OPTS} \
  && docker-php-ext-install gd \
  && docker-php-ext-install gettext \
  && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
  && docker-php-ext-install imap \
  && docker-php-ext-install intl \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install opcache \
  && docker-php-ext-install pdo_mysql \
  && docker-php-ext-install soap \
  && docker-php-ext-install zip
# used?? installed in buildkit...
# && docker-php-ext-install ldap \

COPY etc_apache2_ports.conf /etc/apache2/ports.conf
COPY etc_apache2_sites-available_000-default.conf /etc/apache2/sites-available/000-default.conf

# Install and enable imagick PECL extensions
RUN pecl install imagick \
  && docker-php-ext-enable imagick
# Install xdebug PECL extension
RUN pecl install xdebug \
  && docker-php-ext-enable xdebug

ARG LOGIN_UID=33
ARG LOGIN_GID=${LOGIN_UID}
ARG USER_NAME=docker-user

RUN addgroup --gid=$LOGIN_GID $USER_NAME
RUN useradd --create-home --uid ${LOGIN_UID} --gid ${LOGIN_GID} ${USER_NAME}

RUN a2enmod rewrite headers
