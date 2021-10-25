FROM debian:10-slim

ADD ttyd /usr/bin/ttyd

ADD configure.sh /configure.sh
ADD copyod.ps1 /home/copyod.ps1

RUN apt-get update -y \
    && apt-get install -y curl gnupg apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" > /etc/apt/sources.list.d/microsoft.list' \
    && apt-get update -y \
    && apt-get install -y powershell \
    && chmod +x /configure.sh \
    && chmod +x /usr/bin/ttyd

WORKDIR /home
CMD /configure.sh
