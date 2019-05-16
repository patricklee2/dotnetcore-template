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
userStartupCommand="$@"

function tryStripWwwRootPathFromInput() {
    local originalArg="$1"
    # Strip out the beginning of the argument if it starts with the the appPath
    # Examples: /home/site/wwwroot/app.dll => app.dll
    #           /home/site/wwwroot/app => app
    if case $originalArg in $appPath*) true;; *) false;; esac; then
        sanitizedArg="${originalArg/$appPath/}"
        updatedPath="true"
    else
        sanitizedArg="$originalArg"
    fi
}

# When run from copy is enabled, Oryx tries to run the app from a different directory (local to the container),
# so sanitize any input arguments which still reference the wwwroot path. This is true for VS Publish scenarios.
# Even though VS Publish team might fix this on their end, end users might not have upgraded their extension, so
# this code needs to be present.
if [ "$APP_SVC_RUN_FROM_COPY" = true ]; then
    if [ $# -ne 0 ]; then
        sanitizedInput=""
        # Examples:
        # ./app => ./app
        # dotnet /home/site/wwwroot/app.dll => dotnet app.dll
        # dotnet /home/site/wwwroot/app.dll /home/site/wwwroot/foo.config => dotnet app.dll foo.config
        for arg in "$@"
        do
            tryStripWwwRootPathFromInput $arg
            if [ -z "$sanitizedInput" ]; then
                sanitizedInput="$sanitizedArg"
            else
                sanitizedInput="$sanitizedInput $sanitizedArg"
            fi
        done

        if [ "$updatedPath" == "true" ]; then
            echo "Updated startup command from '$@' to '$sanitizedInput'"
        fi

        userStartupCommand="$sanitizedInput"
    fi
fi

sourcePath="/home/site/repository/"
startupCommandPath="/opt/startup/startup.sh"
defaultAppPath="/defaulthome/hostingstart/hostingstart.dll"
oryxArgs="-appPath $appPath -sourcePath $sourcePath -output $startupCommandPath -defaultAppFilePath $defaultAppPath \
    -bindPort $PORT -userStartupCommand '$userStartupCommand'"

if [ "$APP_SVC_RUN_FROM_COPY" = true ]; then
    oryxArgs="-runFromPath /tmp/webapp $oryxArgs"
fi

echo "Running oryx $oryxArgs"
eval oryx $oryxArgs
$startupCommandPath