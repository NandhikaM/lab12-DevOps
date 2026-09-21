#!/bin/sh
# Usage: sh canary.sh <stable> <canary> <canary_percent 1-99>
set -e
STABLE=$1; CANARY=$2; PCT=$3
OLD=$(docker exec nginx-proxy cat /etc/nginx/active.inc)
WS=$((100 - PCT))

docker exec nginx-proxy sh -c "printf 'server app-$STABLE:3000 weight=$WS;\nserver app-$CANARY:3000 weight=$PCT;\n' > /etc/nginx/active.inc"
if docker exec nginx-proxy nginx -t; then
  docker exec nginx-proxy nginx -s reload
  echo "Traffic split: $STABLE=$WS%  $CANARY=$PCT%"
else
  docker exec nginx-proxy sh -c "echo '$OLD' > /etc/nginx/active.inc"
  echo "nginx config test failed, reverted"; exit 1
fi
