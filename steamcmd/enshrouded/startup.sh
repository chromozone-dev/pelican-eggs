#!/bin/bash
# The server only writes its output to the log file under Proton, so tail it until the server exits
# Wine hangs on startup without a display driver, so give it a virtual X display with xvfb-run
mkdir -p ./logs; : > ./logs/enshrouded_server.log; xvfb-run -a proton run ./enshrouded_server.exe & ENSHROUDED_PID=$!; tail -c0 -F ./logs/enshrouded_server.log --pid=$ENSHROUDED_PID
