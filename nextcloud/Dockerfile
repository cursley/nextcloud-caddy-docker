# Based on https://github.com/nextcloud/docker/blob/master/.examples/dockerfiles/cron/apache/Dockerfile

FROM nextcloud:apache

RUN apt-get update \
    && apt-get install -y supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /

# Add missing database indexes after installation
COPY add-missing-indices.sh /docker-entrypoint-hooks.d/post-installation/

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
