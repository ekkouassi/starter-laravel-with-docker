ARG PHP_VERSION=8.1
ARG LARAVEL_VERSION=10
ARG HTTP_PROXY
ARG HTTPS_PROXY

FROM mlocati/php-extension-installer:1.5.15 AS mlocati
FROM composer:2.4.2 AS composer

FROM php:${PHP_VERSION}-fpm-alpine3.15 AS dev
LABEL vendor="mrke-dev/laravel-starter" maintainer="Ernest KOUASSI<ernest.kouassi@dgitalci.net>" version="0.0.0"

ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}

## Install system dependencies
RUN apk add --no-cache --update --virtual dev-deps \
        $PHPIZE_DEPS && \
    apk add --no-cache \
        libxml2-dev=2.9.14-r2 \
        zlib-dev=1.2.12-r3 \
        libcurl=8.0.1-r0

SHELL ["/bin/sh", "-xo", "pipefail", "-c"]

# Easy installation of PHP extensions
COPY --from=mlocati /usr/bin/install-php-extensions /usr/local/bin/

## Install php extensions
RUN set -ex && \
    docker-php-ext-install bcmath opcache && \
    install-php-extensions apcu-5.1.21 ctype dom fileinfo filter hash mbstring openssl pcre pdo session tokenizer xdebug-3.1.4

COPY docker/php/overrides.ini "$PHP_INI_DIR/conf.d/99-overrides.ini"
COPY docker/php/overrides.conf /usr/local/etc/php-fpm.d/overrides.conf
COPY docker/docker-laravel-entrypoint.sh /usr/local/bin/docker-laravel-entrypoint.sh

RUN wget -q https://github.com/gordalina/cachetool/releases/latest/download/cachetool.phar -O /usr/local/bin/cachetool && \
    wget -q https://raw.githubusercontent.com/eficode/wait-for/v2.2.2/wait-for -O /usr/local/bin/wait-for && \
    chmod +x /usr/local/bin/docker-laravel-entrypoint.sh /usr/local/bin/cachetool /usr/local/bin/wait-for && \
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    echo "xdebug.mode=coverage" >> "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"

COPY docker/crontab /crontab
RUN /usr/bin/crontab -u www-data /crontab

ENTRYPOINT ["docker-laravel-entrypoint.sh"]
CMD ["php-fpm"]

FROM dev AS staging

WORKDIR /app
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

## Install composer
COPY --from=composer /usr/bin/composer /usr/local/bin/

## Copy project files to workdir
COPY --chown=www-data . .

## Install app dependencies
RUN set -ex && \
    composer install --no-interaction --optimize-autoloader --classmap-authoritative && \
    composer clear-cache

FROM staging AS prod

WORKDIR /app

ENV APP_ENV=prod
ENV APP_DEBUG=false

RUN set -ex && \
    composer install --optimize-autoloader --no-dev && \
## Cleanup & Disable xdebug on production
    composer clear-cache && \
	apk del dev-deps && \
	rm -rf /tmp/pear && \
	rm -rf /app/docker && \
	rm /usr/local/bin/composer && \
	rm "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"

