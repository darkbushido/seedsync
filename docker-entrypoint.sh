#!/bin/sh
set -e

cp /config/ssh/* /root/.ssh
chown -R root:root /root/.ssh

exec "$@"