FROM php:8.4.24-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libbz2-dev \
        libfreetype6-dev \
        libgmp-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libldap2-dev \
        libonig-dev \
        libpng-dev \
        libpq-dev \
        libtidy-dev \
        libwebp-dev \
        libxml2-dev \
        libxslt1-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure ldap --with-libdir="lib/$(gcc -dumpmachine)" \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        bz2 \
        calendar \
        exif \
        gd \
        gettext \
        gmp \
        intl \
        ldap \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        shmop \
        soap \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        tidy \
        xsl \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends libffi-dev \
    && docker-php-ext-install -j"$(nproc)" ffi pcntl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY php/php.ini /usr/local/etc/php/conf.d/99-project.ini

WORKDIR /var/www/html
