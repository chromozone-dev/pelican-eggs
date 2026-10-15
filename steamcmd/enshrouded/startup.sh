#!/bin/bash
# The server only writes its output to the log file under Proton, so tail it until the server exits
rm -f ./logs/enshrouded_server.log; proton run ./enshrouded_server.exe & ENSHROUDED_PID=$!; tail -c0 -F ./logs/enshrouded_server.log --pid=$ENSHROUDED_PID
