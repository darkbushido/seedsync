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

ARG USERNAME=seedsync

ENV USERNAME=${USERNAME} \
    UID=1000 \
    GID=1000

RUN apk --update --no-cache add \
    gcc \
    py-gevent \
    musl-dev \
    lftp

WORKDIR /app/

COPY --from=angular /app/build/ng-dist /app/html
COPY src/python     /app/python
COPY .ssh /home/${USERNAME}/.ssh
ADD setup_default_config.sh /scripts/
RUN chmod +x /scripts/setup_default_config.sh

RUN pip install -r /app/python/requirements.txt

# Create non-root user and directories under that user
RUN addgroup -g ${GID} ${USERNAME} \
    && adduser -SD -u ${UID} -G ${USERNAME} ${USERNAME}
RUN mkdir /config && \
    mkdir /downloads && \
    chown ${USERNAME}:${USERNAME} /config && \
    chown ${USERNAME}:${USERNAME} /downloads && \
    chown ${USERNAME}:${USERNAME} /app && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh

# Switch to non-root user
USER ${USERNAME}

RUN /scripts/setup_default_config.sh

CMD [ \
    "python", \
    "/app/python/seedsync.py", \
    "-c", "/config", \
    "--html", "/app/html", \
    "--scanfs", "/app/scanfs" \
]

EXPOSE 8800

VOLUME /config /downloads
