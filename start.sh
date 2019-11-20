#!/bin/sh

cd /srv/taiga/back

INITIAL_SETUP_LOCK=/taiga-conf/.initial_setup.lock
if [ ! -f $INITIAL_SETUP_LOCK ]; then
    touch $INITIAL_SETUP_LOCK

    sed -e 's/$TAIGA_HOST/'$TAIGA_HOST'/' \
        -e 's/$TAIGA_SECRET/'$TAIGA_SECRET'/' \
        -e 's/$TAIGA_SCHEME/'$TAIGA_SCHEME'/' \
        -e 's/$POSTGRES_HOST/'$POSTGRES_HOST'/' \
        -e 's/$POSTGRES_DB/'$POSTGRES_DB'/' \
        -e 's/$POSTGRES_USER/'$POSTGRES_USER'/' \
        -e 's/$POSTGRES_PASSWORD/'$POSTGRES_PASSWORD'/' \
        -e 's/$RABBIT_HOST/'$RABBIT_HOST'/' \
        -e 's/$RABBIT_PORT/'$RABBIT_PORT'/' \
        -e 's/$RABBIT_USER/'$RABBIT_USER'/' \
        -e 's/$RABBIT_PASSWORD/'$RABBIT_PASSWORD'/' \
        -e 's/$RABBIT_VHOST/'$RABBIT_VHOST'/' \
        -i /tmp/taiga-conf/config.py
    cp /tmp/taiga-conf/config.py /taiga-conf/
    ln -sf /taiga-conf/config.py /srv/taiga/back/settings/local.py
    ln -sf /taiga-media /srv/taiga/back/media

    echo 'Waiting for database to become ready...'
    sleep $STARTUP_TIMEOUT
    echo 'Running initial setup...'
    python3 manage.py migrate --noinput
    python3 manage.py loaddata initial_user
    python3 manage.py loaddata initial_project_templates
    python3 manage.py compilemessages
    python3 manage.py collectstatic --noinput
else
    ln -sf /taiga-conf/config.py /srv/taiga/back/settings/local.py
    ln -sf /taiga-media /srv/taiga/back/media

    echo 'Waiting for database to become ready...'
    sleep $STARTUP_TIMEOUT
    echo 'Running database update...'
    python3 manage.py migrate --noinput
    python3 manage.py compilemessages
    python3 manage.py collectstatic --noinput
fi

gunicorn --workers 4 --timeout 60 -b 127.0.0.1:8000 taiga.wsgi > /dev/stdout 2> /dev/stderr &
TAIGA_PID=$!

mkdir /run/nginx
nginx -g 'daemon off;' &
NGINX_PID=$!

trap 'kill -TERM $NGINX_PID; kill -TERM $TAIGA_PID' SIGTERM

wait $NGINX_PID $TAIGA_PID
