FROM caddy:latest

ADD ttyd /usr/bin/ttyd

RUN chmod +x /usr/bin/ttyd

CMD ttyd --port $PORT --credential admin:adminks123 sh
