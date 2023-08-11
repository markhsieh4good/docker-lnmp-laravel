#!/bin/bash

if [ ! -e "./docker-compose.yml" ]; then
  echo "deny, docker-compose.yml cannot found!"
  exit 1
else
  docker-compose -f docker-compose.yml down
fi
