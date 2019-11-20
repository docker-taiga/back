FROM alpine:latest

ARG VERSION=4.2.14

ENV TAIGA_HOST=taiga.lan \
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
	STARTUP_TIMEOUT=15s

WORKDIR /srv/taiga

RUN apk --no-cache add python3 gettext postgresql-dev libxslt-dev libxml2-dev libjpeg-turbo-dev zeromq-dev libffi-dev nginx \
	&& apk add --no-cache --virtual .build-dependencies git g++ musl-dev linux-headers python3-dev zlib-dev libjpeg-turbo-dev freetype-dev \
	&& mkdir logs \
	&& git clone --depth=1 -b $VERSION https://github.com/taigaio/taiga-back.git back && cd back \
	&& pip3 install --no-cache-dir -r requirements.txt \
	&& rm -rf /root/.cache \
	&& apk del .build-dependencies \
	&& rm /srv/taiga/back/settings/local.py.example \
	&& rm /etc/nginx/conf.d/default.conf

EXPOSE 80

WORKDIR /srv/taiga/back

COPY config.py /tmp/taiga-conf/
COPY nginx.conf /etc/nginx/conf.d/
COPY start.sh /

VOLUME ["/taiga-conf", "/taiga-media"]

CMD ["/start.sh"]
