FROM debian:10-slim

ADD ttyd /usr/bin/ttyd

RUN apt-get update -y \
    && apt-get install -y curl gnupg apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - \
    && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list' \
    && apt-get update -y \
    && apt-get install -y powershell \
    && chmod +x /usr/bin/ttyd

CMD ttyd --port $PORT --credential admin:admin --ping-interval 30 bash
