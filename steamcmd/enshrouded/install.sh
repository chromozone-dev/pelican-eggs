#!/bin/bash
# shellcheck disable=SC2155
#
# Enshrouded Installation Script
#
# Server Files: /mnt/server

: "${SERVER_DIR:=/mnt/server}"
: "${STEAM_USER:=anonymous}"
: "${STEAM_PASS:=}"
: "${STEAM_AUTH:=}"
: "${SRCDS_APPID:=2278520}"
: "${SRCDS_BETAID:=}"
: "${SRCDS_BETAPASS:=}"
: "${WINDOWS_INSTALL:=1}"
: "${SERVER_NAME:=Enshrouded Server}"
: "${SERVER_PORT:=15637}"
: "${MAX_PLAYERS:=16}"
: "${GAME_PRESET:=Default}"
: "${ENABLE_VOICE_CHAT:=0}"
: "${VOICE_CHAT_MODE:=Proximity}"
: "${ENABLE_TEXT_CHAT:=0}"
: "${ADMIN_PASSWORD:=}"
: "${FRIEND_PASSWORD:=}"
: "${GUEST_PASSWORD:=}"

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

    create_config

    echo -e "\nInstall completed succesfully, enjoy!"
}

function install_required {
    echo -e "Installing required packages..."
    echo -e "\tRunning apt update"
    apt update > /dev/null 2>&1 || { echo "apt update failed!"; exit 1; }
    echo -e "\tRunning apt install"
    apt install -y wget jq > /dev/null 2>&1 || { echo "apt install failed!"; exit 1; }
}

STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

function download_steamcmd {
    echo -e "Downloading SteamCMD..."
    mkdir -p "$SERVER_DIR/steamcmd" || { echo "Failed to create directory $SERVER_DIR/steamcmd"; exit 1; }

    wget -qO- "$STEAMCMD_URL" | tar -xz -C "$SERVER_DIR/steamcmd" || { echo "Failed to download SteamCMD!"; exit 1; }

    mkdir -p "$SERVER_DIR/steamapps"
}

function download_game {
    echo -e "Downloading Enshrouded..."
    cd "$SERVER_DIR/steamcmd" || { echo "Failed to change directory to $SERVER_DIR/steamcmd"; exit 1; }

    local steamcmd_args=(
        +force_install_dir "$SERVER_DIR"
        +login "$STEAM_USER" "$STEAM_PASS" "$STEAM_AUTH"
    )

    if [[ $WINDOWS_INSTALL -eq 1 ]]; then
        steamcmd_args+=(
            +@sSteamCmdForcePlatformType windows
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
        validate +quit
    )

    echo -e "\tRunning SteamCMD (this may take a while)"
    HOME="$SERVER_DIR" ./steamcmd.sh "${steamcmd_args[@]}" || { echo "Failed to download Enshrouded!"; exit 1; }

    mkdir -p "$SERVER_DIR/.steam/sdk32"
    cp -v "$SERVER_DIR/steamcmd/linux32/steamclient.so" "$SERVER_DIR/.steam/sdk32/steamclient.so"

    mkdir -p "$SERVER_DIR/.steam/sdk64"
    cp -v "$SERVER_DIR/steamcmd/linux64/steamclient.so" "$SERVER_DIR/.steam/sdk64/steamclient.so"

    cd "$SERVER_DIR" || { echo "Failed to change directory to $SERVER_DIR"; exit 1; }
}

function create_config {
    echo -e "Creating server config..."

    # Never overwrite an existing config, it may contain user changes
    if [[ -f enshrouded_server.json ]]; then
        echo -e "\tFound existing enshrouded_server.json, skipping"
        return
    fi

    # The user group order matters, the egg updates passwords by index (0 = Admin, 1 = Friend, 2 = Guest)
    jq -n \
        --arg name "$SERVER_NAME" \
        --argjson port "$SERVER_PORT" \
        --argjson slots "$MAX_PLAYERS" \
        --arg preset "$GAME_PRESET" \
        --argjson voice "$([[ $ENABLE_VOICE_CHAT -eq 1 ]] && echo true || echo false)" \
        --arg voiceMode "$VOICE_CHAT_MODE" \
        --argjson text "$([[ $ENABLE_TEXT_CHAT -eq 1 ]] && echo true || echo false)" \
        --arg admin "$ADMIN_PASSWORD" \
        --arg friend "$FRIEND_PASSWORD" \
        --arg guest "$GUEST_PASSWORD" \
        '{
            name: $name,
            saveDirectory: "./savegame",
            logDirectory: "./logs",
            ip: "0.0.0.0",
            queryPort: $port,
            slotCount: $slots,
            enableVoiceChat: $voice,
            voiceChatMode: $voiceMode,
            enableTextChat: $text,
            gameSettingsPreset: $preset,
            userGroups: [
                { name: "Admin",  password: $admin,  canKickBan: true,  canAccessInventories: true,  canEditBase: true,  canExtendBase: true,  reservedSlots: 0 },
                { name: "Friend", password: $friend, canKickBan: false, canAccessInventories: true,  canEditBase: true,  canExtendBase: false, reservedSlots: 0 },
                { name: "Guest",  password: $guest,  canKickBan: false, canAccessInventories: false, canEditBase: false, canExtendBase: false, reservedSlots: 0 }
            ]
        }' > enshrouded_server.json || { echo "Failed to create enshrouded_server.json"; exit 1; }

    mkdir -p savegame logs
}

main
