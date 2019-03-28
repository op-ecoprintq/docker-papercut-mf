#!/bin/bash

# Fixing permissions after any volume mounts.
chown -R papercut:papercut /home/papercut
chmod +x /home/papercut/server/bin/linux-x64/setperms
/home/papercut/server/bin/linux-x64/setperms

# Perform only if Papercut service exists
if service --status-all 2>&1 | grep -Fq 'pc-app-server'; then

    # If database dir has been volume mounted on host the image database will be overwritten
    # and therefore database needs to initialized
    if [[ ! -d /home/papercut/server/data/internal/derby ]]; then
        runuser -l papercut -c "/home/papercut/server/bin/linux-x64/db-tools init-db -q -f"
    fi

    # If an import hasn't been done before and a database backup file name
    # 'import.zip' exists, perform import.
    if [[ -f /home/papercut/import.zip ]] && [[ ! -f /home/papercut/import.log ]]; then
        runuser -l papercut -c "/home/papercut/server/bin/linux-x64/db-tools import-db -q -f /papercut/import.zip"
    fi

    echo "Starting Papercut service"
    exec systemctl start pc-app-server
else
    echo "Papercut service not found, maybe the docker image/build got corrupted? Exiting..."
fi