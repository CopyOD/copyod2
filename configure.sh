#!/bin/bash
RUN pwsh -Command Install-Module SharePointPnPPowerShellOnline -Force
CMD ttyd --port $PORT --credential $LOGIN_USER:$LOGIN_PASSWORD --ping-interval 30 bash
