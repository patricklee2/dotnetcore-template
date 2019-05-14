#!/usr/bin/env bash
cat >/etc/motd <<EOL 
  _____                               
  /  _  \ __________ _________   ____  
 /  /_\  \\___   /  |  \_  __ \_/ __ \ 
/    |    \/    /|  |  /|  | \/\  ___/ 
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/ 
A P P   S E R V I C E   O N   L I N U X

Documentation: http://aka.ms/webapp-linux
Dotnet quickstart: https://aka.ms/dotnet-qs
.NETCore runtime version: `ls -X /usr/share/dotnet/shared/Microsoft.NETCore.App | tail -n 1`

EOL
cat /etc/motd

# starting sshd process
sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config
/usr/sbin/sshd

appPath="/home/site/wwwroot/"
sourcePath="/home/site/repository/"
startupCommandPath="/opt/startup/startup.sh"
defaultAppPath="/defaulthome/hostingstart/hostingstart.dll"
oryxArgs="-appPath $appPath -sourcePath $sourcePath -output $startupCommandPath -defaultAppFilePath $defaultAppPath \
    -bindPort $PORT -userStartupCommand '$@'"

if [ "$APP_SVC_RUN_FROM_COPY" = true ]; then
    oryxArgs="-runFromPath /tmp/webapp $oryxArgs"
fi

echo "Running oryx $oryxArgs"
eval oryx $oryxArgs
$startupCommandPath