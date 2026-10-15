#!/bin/bash
env $(cat .env | xargs) ./valheim_server.x86_64 -nographics -batchmode -name "{{SERVER_NAME}}" -port {{SERVER_PORT}} -world "{{SERVER_WORLD}}" -password "{{SERVER_PASSWORD}}" -preset {{SERVER_PRESET}} -public {{SERVER_PUBLIC}} $( [[ {{SERVER_CROSSPLAY}} -eq 1 ]] && echo " -crossplay ")
