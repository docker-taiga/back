FROM alpine:3.10

ARG VERSION=5.0.12

ENV TAIGA_HOST=taiga.lan \
    TAIGA_PORT=80 \
    TAIGA_SECRET=secret \
    TAIGA_SCHEME=http \
    POSTGRES_HOST=db \
    POSTGRES_DB=taiga \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD=password \
    RABBIT_HOST=rabbit \
    RABBIT_PORT=5672 \
    RABBIT_USER=taiga \
    RABBIT_PASSWORD=password \
    RABBIT_VHOST=taiga \
    REDIS_HOST=redis \
    REDIS_PORT=6379 \
    REDIS_DB=0 \
    REDIS_PASSWORD=password

WORKDIR /srv/taiga

RUN apk --no-cache add python3 gettext postgresql-dev libxslt-dev libxml2-dev libjpeg-turbo-dev zeromq-dev libffi-dev nginx \
    && apk add --no-cache --virtual .build-dependencies git g++ musl-dev linux-headers python3-dev zlib-dev libjpeg-turbo-dev freetype-dev \
    && mkdir logs \
    && git clone --depth=1 -b $VERSION https://github.com/taigaio/taiga-back.git back && cd back \
    && pip3 install --no-cache-dir -r requirements.txt \
    && rm -rf /root/.cache \
    && apk del .build-dependencies \
    && rm /srv/taiga/back/settings/local.py.example \
    && rm /srv/taiga/back/settings/celery.py \
    && rm /etc/nginx/conf.d/default.conf

EXPOSE 80

WORKDIR /srv/taiga/back

COPY config.py celery.py /tmp/taiga-conf/
COPY nginx.conf /etc/nginx/conf.d/
COPY waitfordb.py /
COPY start.sh /

VOLUME ["/taiga-conf", "/taiga-media"]

CMD ["/start.sh"]
