#!/bin/sh
set -e

if [ -z "$DOMAIN" ]; then
  echo "DOMAIN to obtain a certificate is missing"
  exit 1
fi

if [ -z "$EMAIL" ]; then
  echo "EMAIL is missing"
  exit 2
fi

if [ -z "$KONG_HTTP_ADDR" ]; then
  echo "KONG_HTTP_ADDR is missing"
  exit 3
fi

echo "Launching Certbot Script"
./certbot.sh
