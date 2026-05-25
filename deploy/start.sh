#!/bin/bash

cd /app

if [ ! -f transport.db ]; then
    touch transport.db
fi

/app/server &

nginx -g "daemon off;"
