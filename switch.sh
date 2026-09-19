#!/bin/sh
# Manually point live traffic at blue or green (use this for ROLLBACK).
# Usage: ./switch.sh blue   |   ./switch.sh green
set -e
TARGET=${1:?Usage: ./switch.sh blue|green}
OLD=$(docker exec nginx-proxy cat /etc/nginx/active.inc)

docker exec nginx-proxy sh -c "echo 'server app-$TARGET:3000;' > /etc/nginx/active.inc"
if docker exec nginx-proxy nginx -t; then
  docker exec nginx-proxy nginx -s reload
  echo "Live traffic now -> $TARGET"
else
  docker exec nginx-proxy sh -c "echo '$OLD' > /etc/nginx/active.inc"
  echo "nginx config test failed, reverted" && exit 1
fi
