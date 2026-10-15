#!/bin/bash
# shellcheck disable=SC2155
#
# Valheim Installation Script
#
# Server Files: /mnt/server

: "${SERVER_DIR:=/mnt/server}"
: "${MODPACK_ID:=}"
: "${MODPACK_CODE:=}"
: "${MODPACK_STRING:=}"

function install_required() {
    echo -e "Install required packages..."

    echo -e "\tRunning apt update"
    apt -y update > /dev/null 2>&1 || { echo "apt update failed!"; exit 1; }

    echo -e "\tRunning apt install"
    apt install -y wget jq unzip > /dev/null 2>&1 || { echo "apt install failed!"; exit 1; }

    echo -e "\tInstalling yq"
    wget -qO- https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 | tee /usr/bin/yq > /dev/null 2>&1 || { echo "Failed to download yq"; exit 1; }
    chmod +x /usr/bin/yq
}

STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"

function install_steamcmd() {
    echo -e "Install SteamCMD..."

    echo -e "\tCreating SteamCMD directory"
    mkdir -p "${SERVER_DIR}/steamcmd" || { echo "Failed to create directory ${SERVER_DIR}/steamcmd"; exit 1; }

    echo -e "\tDownloading SteamCMD"
    wget -qO- "${STEAMCMD_URL}" | tar -xz -C "${SERVER_DIR}/steamcmd" || { echo "Failed to download SteamCMD"; exit 1; }

    echo -e "\tSetting environment variables"
    export HOME="${SERVER_DIR}"

    echo -e "\tRunning SteamCMD update (this may take a while)"
    ${SERVER_DIR}/steamcmd/steamcmd.sh +quit > /dev/null 2>&1 || { echo "Failed to update SteamCMD"; exit 1; }
}

function install_valheim() {
    echo -e "Install Valheim..."

    echo -e "\tRunning SteamCMD install (again, this may take a while)"
    ${SERVER_DIR}/steamcmd/steamcmd.sh +force_install_dir ${SERVER_DIR} +login anonymous +app_update 896660 validate +quit > /dev/null 2>&1 || { echo "Failed to install Valheim"; exit 1; }

    echo -en "\tSetting up 32 bit libraries "
    mkdir -p "${SERVER_DIR}/.steam/sdk32" || { echo "Failed to create directory ${SERVER_DIR}/.steam/sdk32"; exit 1; }
    cp -v "${SERVER_DIR}/steamcmd/linux32/steamclient.so" "${SERVER_DIR}/.steam/sdk32/steamclient.so" || { echo "Failed to copy steamclient.so"; exit 1; }

    echo -en "\tSetting up 64 bit libraries "
    mkdir -p "${SERVER_DIR}/.steam/sdk64" || { echo "Failed to create directory ${SERVER_DIR}/.steam/sdk64"; exit 1; }
    cp -v "${SERVER_DIR}/steamcmd/linux64/steamclient.so" "${SERVER_DIR}/.steam/sdk64/steamclient.so" || { echo "Failed to copy steamclient.so"; exit 1; }
}

BEPINEX_URL="https://thunderstore.io/api/experimental/package/denikson/BepInExPack_Valheim/"

function install_bepinex() {
    echo -e "Install BepInEx..."

    echo -e "\tDownloading BepInEx"

    local BEPINEX_JSON=$(wget -q "${BEPINEX_URL}" -O -)
    if [[ -z "${BEPINEX_JSON}" ]]; then
        echo -e "\tERROR: Failed to retrieve BepInEx information from Thunderstore!"
        exit 1
    fi

    local DOWNLOAD_URL=$(echo "${BEPINEX_JSON}" | jq -r '.latest.download_url // empty')
    if [[ -z "${DOWNLOAD_URL}" ]]; then
        echo -e "\tERROR: Failed to retrieve BepInEx download url from Thunderstore!"
        exit 1
    fi

    local DOWNLOAD_VERSION=$(echo "${BEPINEX_JSON}" | jq -r '.latest.version_number // empty')
    if [[ -z "${DOWNLOAD_VERSION}" ]]; then
        echo -e "\tERROR: Failed to retrieve BepInEx version from Thunderstore!"
        exit 1
    fi

    echo -e "\tDownloading BepInEx ${DOWNLOAD_VERSION} from ${DOWNLOAD_URL}"
    wget -q "${DOWNLOAD_URL}" -O bepinex.zip || { echo "Failed to download BepInEx"; exit 1; }

    echo -e "\tUnpacking BepInEx"
    unzip -qo bepinex.zip || { echo "Failed to extract BepInEx"; exit 1; }

    echo -e "\tMoving BepInEx files"
    cp -r ${SERVER_DIR}/BepInExPack_Valheim/* ${SERVER_DIR}

    echo -e "\tCleaning up"
    rm -rf BepInExPack_Valheim bepinex.zip
    rm -rf CHANGELOG.md icon.png manifest.json README.md
}

THUNDERSTORE_PACKAGE_URL="https://thunderstore.io/api/experimental/package/"
THUNDERSTORE_PROFILE_URL="https://thunderstore.io/api/experimental/legacyprofile/get/"
THUNDERSTORE_DOWNLOAD_URL="https://thunderstore.io/package/download"

function install_modpack() {
    echo -e "Install modpack..."

    # The modpack is provided in 1 of 3 ways:
    #    1. MODPACK_ID is set to a Thunderstore modpack id
    #    2. MODPACK_CODE is set to a Thunderstore modpack code
    #    3. MODPACK_STRING is set to a Thunderstore modpack string (dependency string)

    echo -e "\tRetrieving modpack information"
    if [[ -n "${MODPACK_ID}" ]]; then
        echo -e "\tUsing modpack id '${MODPACK_ID}'"

        MODPACK_ID=$(echo "${MODPACK_ID}" | sed 's/-/\//g')

        # Split into author, name, and version
        local author=$(echo "${MODPACK_ID}" | cut -d'/' -f1)
        local name=$(echo "${MODPACK_ID}" | cut -d'/' -f2)
        local version=$(echo "${MODPACK_ID}" | cut -d'/' -f3)

        if [[ -z "${version}" ]]; then
            echo -e "\tRetrieving Thunderstore data for '${author}/${name}' (latest)"

            MODPACK_STRING=$(wget -q "${THUNDERSTORE_PACKAGE_URL}${author}/${name}" -O - | jq -r '.latest.dependencies[] // empty')
        else
            echo -e "\tRetrieving Thunderstore data for '${author}/${name}' (${version})"

            MODPACK_STRING=$(wget -q "${THUNDERSTORE_PACKAGE_URL}${author}/${name}/${version}" -O - | jq -r '.dependencies[] // empty')
        fi
    elif [[ -n "${MODPACK_CODE}" ]]; then
        echo -e "\tUsing modpack code '${MODPACK_CODE}'"

        echo -e "\tDownload Thunderstore profile"
        local MODPACK_DATA=$(wget -q "${THUNDERSTORE_PROFILE_URL}${MODPACK_CODE}" -O -)

        if [[ $(echo "${MODPACK_DATA}" | head -n 1) != "#r2modman" ]]; then
            echo -e "\tERROR: Failed to retrieve modpack data from Thunderstore!"
            exit 1
        fi

        echo "${MODPACK_DATA}" | tail -n 1 | base64 -d > import.r2z

        unzip -p import.r2z export.r2x > export.r2x

        local MODPACK_NAME=$(yq e '.profileName' export.r2x)
        echo -e "\tUsing modpack name '${MODPACK_NAME}'"

        local MODPACK_MODS=$(yq e '.mods[] | .name + "-" + .version.major + "." + .version.minor + "." + .version.patch' export.r2x)

        MODPACK_STRING=$(echo "${MODPACK_MODS}" | sed 's/^[ \t]*//;s/[ \t]*$//')

        echo -e "\tCopying profile contents"
        unzip -oq import.r2z "BepInEx/*" -d ${SERVER_DIR}

        rm -rf import.r2z export.r2x
    elif [[ -n "${MODPACK_STRING}" ]]; then
        # If the string is space separated instead of newline, convert it
        MODPACK_STRING=$(echo "${MODPACK_STRING}" | sed 's/ /\\n/g')
        MODPACK_STRING=$(echo -e "${MODPACK_STRING}")

        echo -e "\tUsing modpack string"
    else
        echo -e "\tNo modpack provided, skipping mod installation!"
        return
    fi

    echo -e "\tDeleting old mods"
    rm -rf ${SERVER_DIR}/BepInEx/plugins/*

    echo -e "\tDownloading mods"

    mkdir -p ${SERVER_DIR}/BepInEx/plugins

    for mod in ${MODPACK_STRING}; do
        local author=$(echo "${mod}" | cut -d'-' -f1)
        local name=$(echo "${mod}" | cut -d'-' -f2)
        local version=$(echo "${mod}" | cut -d'-' -f3)

        if [[ "${name}" == "BepInExPack_Valheim" ]]; then
            continue
        fi

        local package_json=$(wget -q "${THUNDERSTORE_PACKAGE_URL}${author}/${name}/" -O -)
        if [[ -z "${package_json}" ]]; then
            echo -e "\t\tERROR: Failed to retrieve mod information for '${author}/${name}'"
            continue
        fi

        # Find community_listing where community == "valheim"
        local community_listing=$(echo "${package_json}" | jq -r '.community_listings[]? | select(.community == "valheim") // empty')
        if [[ -z "${community_listing}" ]]; then
            echo -e "\t\tWARNING: Mod '${author}/${name}' is not listed for Valheim!"
        fi

        # If community listing has "Client-side" in categories but not "Server-side", skip it
        if [[ -n "${community_listing}" && $(echo "${community_listing}" | jq -r 'any(.categories[]; . == "Client-side") and all(.categories[]; . != "Server-side")') == "true" ]]; then
            echo -e "\t\tWARNING: Mod '${author}/${name}' is client-side only!"
            continue
        fi

        local mod_json=$(wget -q "${THUNDERSTORE_PACKAGE_URL}${author}/${name}/${version}/" -O -)
        if [[ -z "${mod_json}" ]]; then
            echo -e "\t\tERROR: Failed to retrieve mod information for '${author}/${name}'"
            continue
        fi

        # Check if all dependencies exist in the modpack
        local dependencies=$(echo "${mod_json}" | jq -r '.dependencies[] // empty')
        for dependency in ${dependencies}; do
            # Only check the modname itself, ignore the version
            local dependency_name=$(echo "${dependency}" | cut -d'-' -f2)
            if [[ "${dependency_name}" == "BepInExPack_Valheim" ]]; then
                continue
            fi

            if [[ ! "${MODPACK_STRING}" =~ "${dependency_name}" ]]; then
                echo -e "\t\tWARNING: Mod '${author}/${name}' depends on '${dependency_name}' which is not in the modpack!"
            fi
        done

        echo -e "\t\tDownloading mod '${name}' (${version}) by ${author}"
        wget -q "${THUNDERSTORE_DOWNLOAD_URL}/${author}/${name}/${version}" -O "${name}.zip" || { echo "Failed to download mod ${name}"; exit 1; }

        echo -e "\t\tUnpacking mod '${name}'"
        # unzip -oq "${name}.zip" "*.dll" -d "${SERVER_DIR}/BepInEx/plugins"

        # Unfortunately Thunderstore mods can be shipped in multiple ways
        # See: https://github.com/ebkr/r2modmanPlus/wiki/Structuring-your-Thunderstore-package#bepinex

        # Extract all files to a temporary directory first
        local tmp_dir="${SERVER_DIR}/tmp_${name}"
        mkdir -p "${tmp_dir}"
        unzip -qo "${name}.zip" -d "${tmp_dir}"

        # Some mods are dumb and ship a BepInEx folder, move its contents up one level
        if [[ -d "${tmp_dir}/BepInEx" ]]; then
            mv "${tmp_dir}/BepInEx"/* "${tmp_dir}/"
            rm -rf "${tmp_dir}/BepInEx"
        fi

        # Handle special BepInEx directories with author-modname subdirectories
        local author_mod="${author}-${name}"
        for dir in "patchers" "plugins" "core" "monomod"; do
            if [[ -d "${tmp_dir}/${dir}" ]]; then
                mkdir -p "${SERVER_DIR}/BepInEx/${dir}/${author_mod}"
                cp -r "${tmp_dir}/${dir}"/* "${SERVER_DIR}/BepInEx/${dir}/${author_mod}/"
                rm -rf "${tmp_dir}/${dir}"
            fi
        done

        # Handle config directory (no author-modname subdirectory)
        if [[ -d "${tmp_dir}/config" ]]; then
            mkdir -p "${SERVER_DIR}/BepInEx/config"
            cp -r "${tmp_dir}/config"/* "${SERVER_DIR}/BepInEx/config/"
            rm -rf "${tmp_dir}/config"
        fi

        # Check if any *.mm.dll exist in ANY level of the directory tree
        if [[ -n $(find "${tmp_dir}" -name "*.mm.dll") ]]; then
            mkdir -p "${SERVER_DIR}/BepInEx/monomod/${author_mod}"
        fi

        # Any *.mm.dll in ANY level of the directory tree should be moved to monomod
        find "${tmp_dir}" -name "*.mm.dll" -exec mv {} "${SERVER_DIR}/BepInEx/monomod/${author_mod}/" \;

        if [[ -n $(find "${tmp_dir}" -name "*.dll") ]]; then
            mkdir -p "${SERVER_DIR}/BepInEx/plugins/${author_mod}"
        fi

        # Any remaining *.dll files should be moved to plugins
        find "${tmp_dir}" -name "*.dll" -exec mv {} "${SERVER_DIR}/BepInEx/plugins/${author_mod}/" \;

        # Handle remaining files - they go to plugins by default
        if [[ -d "${tmp_dir}" ]]; then
            mkdir -p "${SERVER_DIR}/BepInEx/plugins/${author_mod}"
            # Move all remaining files and directories
            cp -r "${tmp_dir}"/* "${SERVER_DIR}/BepInEx/plugins/${author_mod}/"
        fi

        # Delete any empty directory
        find "${SERVER_DIR}/BepInEx" -type d -empty -delete

        # Cleanup
        rm -rf "${tmp_dir}"
        rm -rf "${name}.zip"
    done
}

function install_environment() {
    echo -e "Install environment..."

    # We need to copy all export commands from start_server_bepinex.sh into a .env file
    grep -oP 'export \K\S+' start_server_bepinex.sh > .env
}

function main() {
    if [[ ! -d "${SERVER_DIR}" ]]; then
        mkdir -p "${SERVER_DIR}"
    fi

    if ! cd "${SERVER_DIR}"; then
        echo "Failed to change directory to ${SERVER_DIR}"
        exit 1
    fi

    install_required
    install_steamcmd
    install_valheim
    install_bepinex
    install_modpack
    install_environment

    echo -e "Install completed succesfully, enjoy!"
}

main
