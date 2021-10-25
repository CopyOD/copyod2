FROM debian:10-slim

ADD ttyd /usr/bin/ttyd

RUN chmod +x /usr/bin/ttyd

CMD ttyd --port $PORT --credential admin:admin --ping-interval 30 sh
