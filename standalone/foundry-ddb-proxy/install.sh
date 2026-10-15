#!/bin/bash
# shellcheck disable=SC2155
#
# Foundry DDB Proxy Installation Script
#
# Server Files: /mnt/server

: "${SERVER_DIR:=/mnt/server}"

function install_required {
    echo -e "Installing required packages..."
    echo -e "\tRunning apt update"
    apt update > /dev/null 2>&1 || { echo "apt update failed!"; exit 1; }
    echo -e "\tRunning apt install"
    apt install -y wget jq unzip > /dev/null 2>&1 || { echo "apt install failed!"; exit 1; }

    echo -e "\tInstalling NodeJS"
    apt install -y nodejs npm --no-install-recommends

    echo -e "\tInstalling Yarn"
    npm install -g yarn
}

DDB_PROXY_REPO="MrPrimate/ddb-proxy"

function download_proxy {
    echo -e "Downloading Foundry DDB Proxy..."

    # Get latest release tag
    local latest_tag=$(curl -s https://api.github.com/repos/$DDB_PROXY_REPO/releases/latest | jq -r .tag_name)

    # Download latest release
    wget -q "https://github.com/$DDB_PROXY_REPO/archive/refs/tags/$latest_tag.zip" -O ddb-proxy.zip || { echo "Failed to download Foundry DDB Proxy!"; exit 1; }

    # Extract latest release
    unzip -q ddb-proxy.zip || { echo "Failed to extract Foundry DDB Proxy!"; exit 1; }

    # It gets unzipped to ddb-proxy-* folder
    local ddb_proxy_dir=$(ls -d ddb-proxy-*)
    mv -f "$ddb_proxy_dir"/* .
    rm -rf "$ddb_proxy_dir"

    # Clean up
    rm -f ddb-proxy.zip

    echo -e "\tFoundry DDB Proxy downloaded and extracted successfully!"
}

function setup_proxy {
    echo -e "Setting up Foundry DDB Proxy..."

    yarn install
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

    download_proxy

    setup_proxy

    echo -e "\nInstall completed succesfully, enjoy!"
}

main
