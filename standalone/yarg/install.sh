#!/bin/bash
# shellcheck disable=SC2155
#
# YARG Installation Script
#
# Server Files: /mnt/server

: "${SERVER_DIR:=/mnt/server}"

function install_required {
    echo -e "Installing required packages..."
    echo -e "\tRunning apt update"
    apt update > /dev/null 2>&1 || { echo "apt update failed!"; exit 1; }
    echo -e "\tRunning apt install"
    apt install -y wget jq unzip > /dev/null 2>&1 || { echo "apt install failed!"; exit 1; }
}

YARG_SERVER_URL="https://rockbanddeluxesigmas.rocks/files/YARG-online-beta-server-linux.zip"

function download_yarg {
    echo -e "Downloading YARG server files..."
    wget -q "$YARG_SERVER_URL" -O YARG.zip || { echo "Failed to download YARG server files!"; exit 1; }

    # The ZIP file contains a folder called linux_server, which then contains the server files, so we need to skip the first folder when extracting

    echo -e "\tExtracting YARG server files..."
    unzip -q YARG.zip "linux_server/*" || { echo "Failed to extract YARG server files!"; exit 1; }

    echo -e "\tMoving YARG server files..."
    mv -f linux_server/* .

    echo -e "\tRemoving linux_server folder..."
    rm -rf linux_server

    echo -e "\tCleaning up..."
    rm -f YARG.zip

    echo -e "\tSetting permissions..."
    chmod -R 755 "$SERVER_DIR"
    chmod +x "$SERVER_DIR/YARG.x86_64"

    echo -e "\tYARG server files downloaded and extracted successfully!"
}

function main {
    if [[ ! -d $SERVER_DIR ]]; then
        mkdir -p "$SERVER_DIR"
    fi

    if ! cd "$SERVER_DIR"; then
        echo -e "Failed to change directory to ${SERVER_DIR}"
        exit 1
    fi

    install_required

    download_yarg

    echo -e "\nInstall completed succesfully, enjoy!"
}

main
