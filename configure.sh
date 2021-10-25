#!/bin/bash
pwsh -Command Install-Module SharePointPnPPowerShellOnline -Force
ttyd --port $PORT --credential $LOGIN_USER:$LOGIN_PASSWORD --ping-interval 30 bash
