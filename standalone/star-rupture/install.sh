#!/bin/bash
# shellcheck disable=SC2155
#
# StarRupture Installation Script
#
# Server Files: /mnt/server

: "${SERVER_DIR:=/mnt/server}"
: "${STEAM_USER:=anonymous}"
: "${STEAM_PASS:=}"
: "${STEAM_AUTH:=}"
: "${SRCDS_APPID:=3809400}"
: "${SRCDS_BETAID:=}"
: "${SRCDS_BETAPASS:=}"
: "${SRCDS_WINDOWS:=1}"
: "${SRCDS_FLAGS:=}"

function main {
    if [[ ! -d $SERVER_DIR ]]; then
        mkdir -p "$SERVER_DIR"
    fi

    if ! cd "$SERVER_DIR"; then
        echo -e "Failed to change directory to ${SERVER_DIR}"
        exit 1
    fi

    install_required

    download_steamcmd

    download_game

    echo -e "\nInstall completed succesfully, enjoy!"
}

function install_required {
    echo -e "Installing required packages..."
    echo -e "\tRunning apt update"
    apt update > /dev/null 2>&1 || { echo "apt update failed!"; exit 1; }
    echo -e "\tRunning apt install"
    apt install -y wget jq unzip > /dev/null 2>&1 || { echo "apt install failed!"; exit 1; }
}

STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

function download_steamcmd {
    echo -e "Downloading SteamCMD..."
    cd /tmp || { echo "Failed to change directory to /tmp"; exit 1; }

    wget -q "$STEAMCMD_URL" -O steamcmd.tar.gz || { echo "Failed to download SteamCMD!"; exit 1; }

    mkdir -p "$SERVER_DIR/steamcmd" || { echo "Failed to create directory $SERVER_DIR/steamcmd"; exit 1; }

    echo -e "\tExtracting SteamCMD..."
    tar -xzvf steamcmd.tar.gz -C "$SERVER_DIR/steamcmd" || { echo "Failed to extract SteamCMD!"; exit 1; }

    mkdir -p "$SERVER_DIR/steamapps"
}

function download_game {
    echo -e "Downloading Game..."
    cd "$SERVER_DIR/steamcmd" || { echo "Failed to change directory to $SERVER_DIR/steamcmd"; exit 1; }

    local steamcmd_args=(
        +force_install_dir "$SERVER_DIR"
        +login "$STEAM_USER" "$STEAM_PASS" "$STEAM_AUTH"
    )

    if [[ $SRCDS_WINDOWS -eq 1 ]]; then
        steamcmd_args+=(
            "+@sSteamCmdForcePlatformType windows"
        )
    fi

    steamcmd_args+=(
        +app_update "$SRCDS_APPID"
    )

    if [[ -n $SRCDS_BETAID ]]; then
        steamcmd_args+=(
            -beta "$SRCDS_BETAID"
        )
    fi

    if [[ -n $SRCDS_BETAPASS ]]; then
        steamcmd_args+=(
            -betapassword "$SRCDS_BETAPASS"
        )
    fi

    steamcmd_args+=(
        "$SRCDS_FLAGS"
    )

    steamcmd_args+=(
        validate +quit
    )

    # Print out arguments
    echo -e "\tSteamCMD Arguments:"
    for arg in "${steamcmd_args[@]}"; do
        echo -e "\t\t$arg"
    done
    echo -e "\tEnd SteamCMD Arguments"

    HOME="$SERVER_DIR" ./steamcmd.sh "${steamcmd_args[@]}" || { echo "Failed to download game!"; exit 1; }

    mkdir -p "$SERVER_DIR/.steam/sdk32"
    cp -v "$SERVER_DIR/steamcmd/linux32/steamclient.so" "$SERVER_DIR/.steam/sdk32/steamclient.so"

    mkdir -p "$SERVER_DIR/.steam/sdk64"
    cp -v "$SERVER_DIR/steamcmd/linux64/steamclient.so" "$SERVER_DIR/.steam/sdk64/steamclient.so"
}

main
