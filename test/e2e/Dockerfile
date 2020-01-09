FROM node:13.5-buster-slim

WORKDIR /app

COPY package.json /app/package.json

RUN npm install
RUN npm install -g @angular/cli

COPY . /app
ENV PATH /app/node_modules/.bin:$PATH

ENV DOCKERIZE_VERSION v0.6.1
RUN curl -L -sS https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz |\
    gzip -dc | \
    tar -C /usr/local/bin -xv

CMD ["./run_tests.sh"]
