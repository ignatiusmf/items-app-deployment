#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: ./get_item.sh <hostname:port> <item_id>"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Usage: ./get_item.sh <hostname:port> <item_id>"
  exit 1
fi

curl "http://$1/items/$2"