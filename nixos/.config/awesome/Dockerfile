FROM wordpress:latest

# Instala mysql-client y wp-cli
RUN apt-get update \
 && apt-get install -y default-mysql-client \
 && rm -rf /var/lib/apt/lists/* \
 && curl -sSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

# Insatla gosu para correr la instalación como el usuario www-data
ENV GOSU_VERSION=1.14

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg dirmngr; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"; \
    chmod +x /usr/local/bin/gosu; \
    gosu nobody true; \
    apt-get purge -y --auto-remove wget gnupg dirmngr; \
    rm -rf /var/lib/apt/lists/*

# Copia el entrypoint personalizado y el script de instalación WP
COPY entrypoint.sh       /usr/local/bin/entrypoint.sh
COPY wp-init/install-wp.sh /usr/local/bin/install-wp.sh
COPY .htaccess.template  /etc/wordpress/.htaccess.template

RUN chmod +x /usr/local/bin/entrypoint.sh \
	/usr/local/bin/install-wp.sh

# Crea carpeta de logs
RUN mkdir -p /var/log/orinoquia \
	&& chown www-data:www-data /var/log/orinoquia

# Carga el entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]