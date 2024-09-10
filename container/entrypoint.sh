#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Function to handle shutdown when sigterm is recieved
shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    kill -2 $satisfactory_pid
}

# Set our trap
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat /home/steam/image_version)
MAINTAINER=$(cat /home/steam/image_maintainer)
EXPECTED_FS_PERMS=$(cat /home/steam/expected_filesystem_permissions)

echo "$(timestamp) INFO: Launching Satisfactory Dedicated Server image ${IMAGE_VERSION} by ${MAINTAINER}"

# Check for proper save permissions
echo "$(timestamp) INFO: Validating data directory filesystem permissions"
if ! touch "${SATISFACTORY_PATH}/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of ${SATISFACTORY_PATH} is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by ${EXPECTED_FS_PERMS}"
    echo "from your container host attempt the following command 'sudo chown -R ${EXPECTED_FS_PERMS} /your/satisfactory/data/directory'"
    echo ""
    exit 1
fi

rm "${SATISFACTORY_PATH}/test"

# Install/Update Satisfactory
echo "$(timestamp) INFO: Updating Satisfactory Dedicated Server"
echo ""
${STEAMCMD_PATH}/steamcmd.sh +force_install_dir "${SATISFACTORY_PATH}" +login anonymous +app_update ${STEAM_APP_ID} validate +quit
echo ""

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Satisfactory"
    exit 1
else
    echo "$(timestamp) INFO: steamcmd update of Satisfactory successful"
fi

echo ""
echo "$(timestamp) INFO: Launching Satisfactory!"
echo "--------------------------------------------------------------------------------"
echo "Game Port: ${GAME_PORT}"
echo "Query Port: ${QUERY_PORT}"
echo "Beacon Port: ${BEACON_PORT}"
echo "Multihome: ${MULTIHOME}"
echo "Container Image Version: ${IMAGE_VERSION} "
echo "--------------------------------------------------------------------------------"
echo ""
echo ""

# Launch Satisfactory
${SATISFACTORY_PATH}/FactoryServer.sh -ServerQueryPort=${QUERY_PORT} -BeaconPort=${BEACON_PORT} -Port=${GAME_PORT} -multihome=${MULTIHOME} &

# Find pid for FactoryServer-Linux-Shipping
timeout=0
while [ $timeout -lt 11 ]; do
    if ps -e | grep "FactoryServer-L"; then
        satisfactory_pid=$(ps -e | grep "FactoryServer-L" | awk '{print $1}')
        break
    elif [ $timeout -eq 10 ]; then
        echo "$(timestamp) ERROR: Timed out waiting for FactoryServer-Linux-Shipping to be running"
        exit 1
    fi
    sleep 6
    ((timeout++))
    echo "$(timestamp) INFO: Waiting for FactoryServer-Linux-Shipping to be running"
done

# Hold us open until we recieve a SIGTERM
wait

# Handle post SIGTERM from here
# Hold us open until pid closes, indicating full shutdown, then go home
tail --pid=$satisfactory_pid -f /dev/null

# o7
echo "$(timestamp) INFO: Shutdown complete."
exit 0
