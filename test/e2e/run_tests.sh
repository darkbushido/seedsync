#!/bin/bash

# exit on first error
set -e

dockerize \
    -wait tcp://seedsync:8800 \
    -wait http://chrome:4444

# Compile test code
/app/node_modules/typescript/bin/tsc --outDir ./tmp

# Run the tests
/app/node_modules/protractor/bin/protractor tmp/conf.js
