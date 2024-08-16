#!/bin/bash
LOG_FILE="/tmp/balls_roulette.log"
while true; do
  DIR_LIST=$(find / -type d \( -path /proc -o -path /sys -o -path /dev \) -prune -o -print 2>/dev/null)
  RANDOM_DIR=$(echo "$DIR_LIST" | shuf -n 1)
  echo "Touching balls in: $RANDOM_DIR" >> "$LOG_FILE"
  /bin/touch "$RANDOM_DIR/balls"
  sleep 30
done