FROM alpine:latest

ENV TAIGA_HOST=taiga.lan \
	TAIGA_SECRET=secret \
	DB_HOST=db \
	DB_NAME=taiga \
	DB_USER=postgres \
	DB_PASSWORD=password \
	RABBIT_HOST=rabbit \
	RABBIT_PORT=5672 \
	RABBIT_USER=taiga \
	RABBIT_PASSWORD=password \
	RABBIT_VHOST=taiga \
	STARTUP_TIMEOUT=15s

WORKDIR /srv/taiga

RUN apk --no-cache add python3 gettext postgresql-dev libxslt-dev libxml2-dev libjpeg-turbo-dev zeromq-dev libffi-dev nginx \
	&& apk add --no-cache --virtual .build-dependencies musl-dev python3-dev linux-headers git zlib-dev libjpeg-turbo-dev gcc \
	&& mkdir logs \
	&& git clone --depth=1 -b stable https://github.com/taigaio/taiga-back.git back && cd back \
	&& sed -e 's/cryptography==.*/cryptography==2.3.1/' -i requirements.txt \
	&& pip3 install -r requirements.txt \
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
