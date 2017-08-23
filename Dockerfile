FROM wonderfall/searx

ENV DOCKERIZE_VERSION v0.5.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz

RUN apk -U upgrade \
    && apk add -t build-dependencies build-base python-dev \
    && apk add uwsgi uwsgi-python \
    && rm -f /var/cache/apk/*

WORKDIR /usr/local/searx-admin

RUN pip install --no-cache -r https://raw.githubusercontent.com/kvch/searx-admin/master/requirements.txt

RUN wget -qO- https://github.com/kvch/searx-admin/archive/master.tar.gz | tar xz --strip 1

ADD . /usr/local/searx-admin
RUN ln -s /usr/sbin/uwsgi /usr/bin/uwsgi

ENV SEARX_UWSGI_EXTRA_ARGS "['--uid', '${UID}']"

RUN adduser searx -u $UID -DH

RUN sed -i 's/bind_address : "127.0.0.1"/bind_address : "0.0.0.0"/' admin/reference_settings.yml

RUN export APP_SECRETKEY=$(openssl rand -hex 16)
ENV APP_DATA_PATH "/var/lib/searx"
ENV APP_DATABASE_CONNECTION_STRING "sqlite:////var/lib/searx/users.db"

CMD dockerize -template admin/config.yml.tmpl:admin/config.yml -- python admin/webapp.py
