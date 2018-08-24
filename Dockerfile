FROM josebovet/certbot-cloudflare
COPY /inc/entrypoint.sh inc/dns-server.ini inc/certbot.sh /
ENTRYPOINT ["/entrypoint.sh"]
