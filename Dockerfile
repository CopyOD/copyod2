FROM alpine:latest

ADD ttyd /usr/bin/ttyd

RUN chmod +x /usr/bin/ttyd

CMD ttyd --port $PORT --credential admin:admin --ping-interval 60 sh
