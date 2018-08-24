#!/bin/sh
# Certbot script.
# Written by Jose Bovet Derpich <jose.bovet@gmail.com>
# Written by Miguel Herrera <migueljherrera@gmail.com>
CERTS_PATH=/etc/letsencrypt/live

echo "Running certbot with DOMAIN: $DOMAIN, EMAIL: $EMAIL"
CERT_OUT=`certbot certonly --agree-tos --dns-cloudflare --dns-cloudflare-credentials dns-server.ini -d $DOMAIN -n -m $EMAIL`
OUT=$?

if [ $OUT -ne 0 ]; then
    echo "Error executing certbot."
    echo "$CERT_OUT"
    exit 1
fi

NO_ACTION="no action taken"
if echo "$CERT_OUT" | grep -q "$NO_ACTION"; then
  exit 2
fi

echo "Verifying certificates generated for $DOMAIN"
if [ -z "$(ls -A $CERTS_PATH/$DOMAIN)" ]; then
  echo "Certificates cannot be generated for domain $DOMAIN"
  exit 3
fi

RETRY=1
HTTP_STATUS=0
SLEEP=5
 until [ $RETRY -gt 3 ]
 do
    echo "Try $RETRY Uploading Certificates to $KONG_HTTP_ADDR"
    RETRY=$((RETRY+1))
    DELETE_STATUS=$(curl --write-out %{http_code} --silent --output /dev/null -X DELETE $KONG_HTTP_ADDR/certificates/$DOMAIN)

    if [ "$DELETE_STATUS" -eq 404 ] || [ "$DELETE_STATUS" -eq 204 ] ; then
      HTTP_STATUS=$(curl --write-out %{http_code} --silent --output /dev/null --connect-timeout 15 -X POST $KONG_HTTP_ADDR/certificates \
          -F "cert=@$CERTS_PATH/$DOMAIN/fullchain.pem" \
          -F "key=@$CERTS_PATH/$DOMAIN/privkey.pem" \
          -F "snis=$DOMAIN")
      RETURN_CODE=$?
      if [ "$RETURN_CODE" -ne 0 ] || [ "$HTTP_STATUS" -ne 201 ]; then
        echo "Problem uploading certiticates, trying again..."
        sleep $SLEEP
        continue
      fi

      echo "Certificates uploaded successfully"
      break
    fi

    echo "Problem deleting certiticates, trying again..."
    sleep $SLEEP
    continue
 done

if [ "$HTTP_STATUS" -ne 201 ]; then
 echo "ERROR - Certbot cannot upload certificates."
 exit 4
fi
