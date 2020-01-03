FROM python:3.6-alpine AS angular

ENV SOURCEDIR /app/src
ENV BUILDDIR  /app/build

RUN apk --update --no-cache add npm

WORKDIR ${SOURCEDIR}/angular
COPY src/angular .
RUN npm install -g @angular/cli
RUN npm install
RUN ng build -prod --output-path ${BUILDDIR}/ng-dist

FROM python:3.6-alpine as seedsync

RUN apk --update --no-cache add \
    openssh-client \
    gcc \
    py-gevent \
    musl-dev \
    lftp

WORKDIR /app/

COPY --from=angular /app/build/ng-dist /app/html
COPY src/python     /app/python
COPY setup_default_config.sh    /usr/local/bin/
COPY docker-entrypoint.sh       /usr/local/bin/

RUN chmod -R +x /usr/local/bin/

RUN pip install -r /app/python/requirements.txt

# Create non-root user and directories under that user
RUN mkdir -p /config/ssh && \
    mkdir /downloads 

RUN mkdir -p /root/.ssh
COPY ssh /root/.ssh
COPY ssh /config/ssh

RUN setup_default_config.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ \
    "python", \
    "/app/python/seedsync.py", \
    "-c", "/config", \
    "--html", "/app/html", \
    "--scanfs", "/app/python/scan_fs.py" \
]

EXPOSE 8800

# VOLUME /config /downloads
