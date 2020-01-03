FROM python:3.6-alpine AS angular

ENV SOURCEDIR /src
ENV BUILDDIR  /build

RUN apk --update --no-cache add npm

WORKDIR ${SOURCEDIR}
COPY src/angular .
RUN npm install -g @angular/cli
RUN npm install
RUN ng build -prod --output-path ${BUILDDIR}/ng-dist

FROM python:3.6-alpine AS pythonbase

RUN apk --update --no-cache add \
    py-gevent \
    gcc \
    musl-dev

COPY src/python/requirements.txt     /src/requirements.txt
RUN pip install -r /src/requirements.txt
COPY src/python/ /src

FROM pythonbase AS scanfs

ENV SOURCEDIR /src
ENV BUILDDIR  /build

# Official Python base image is needed or some applications will segfault.
# PyInstaller needs zlib-dev, gcc, libc-dev, and musl-dev
RUN apk --update --no-cache add \
    zlib-dev \
    libc-dev \
    libffi-dev \
    g++ \
    git \
    pwgen
    # && pip install --upgrade pip

# Install pycrypto so --key can be used with PyInstaller
RUN pip install \
    pycrypto

# Build bootloader for alpine
RUN git clone --depth 1 --single-branch --branch v3.4 https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && CFLAGS="-Wno-stringop-overflow" python ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller

ADD ./bin /pyinstaller
RUN chmod a+x /pyinstaller/*

WORKDIR /src

RUN /pyinstaller/pyinstaller.sh ${SOURCEDIR}/scan_fs.py \
    -y \
    --onefile \
    -p ${SOURCEDIR} \
    --distpath ${BUILDDIR}/scanfs-dist \
    --workpath ${BUILDDIR}/scanfs-work \
    --specpath ${BUILDDIR} \
    --name scanfs

FROM pythonbase as seedsync

ENV BUILDDIR  /build

RUN apk --update --no-cache add \
    openssh-client \
    lftp

WORKDIR /app/

COPY --from=angular ${BUILDDIR}/ng-dist             /app/html
COPY --from=scanfs  ${BUILDDIR}/scanfs-dist/scanfs  /app/scanfs
COPY setup_default_config.sh    /usr/local/bin/
COPY docker-entrypoint.sh       /usr/local/bin/

RUN chmod -R +x /usr/local/bin/

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
    "/src/seedsync.py", \
    "-c", "/config", \
    "--html", "/app/html", \
    "--scanfs", "/app/scanfs" \
]

EXPOSE 8800

VOLUME /config /downloads
