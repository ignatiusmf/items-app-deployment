#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: ./add_item.sh <hostname:port> <name> <description> (optional)"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Usage: ./add_item.sh <hostname:port> <name> <description> (optional)"
  exit 1
fi

if [ -z "$3" ]; then
  DESCRIPTION="null"
else
  DESCRIPTION="\"$3\""
fi


curl -X POST "http://$1/items" \
     -H "Content-Type: application/json" \
     -d "{\"name\": \"$2\", \"description\": $DESCRIPTION}"

