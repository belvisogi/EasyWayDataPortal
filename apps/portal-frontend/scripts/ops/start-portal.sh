#!/bin/bash
# Sovereign Portal Startup Script
# Re-launches the Python HTTP server if not running

PORT=8080
DIR="/home/ubuntu/portal-frontend"
LOG="/home/ubuntu/portal-server.log"

# Check if port is already in use
if lsof -i :$PORT > /dev/null; then
    echo "$(date): Portal already running on port $PORT" >> $LOG
else
    echo "$(date): Starting Portal on port $PORT..." >> $LOG
    nohup python3 -m http.server $PORT --directory $DIR >> $LOG 2>&1 &
fi
