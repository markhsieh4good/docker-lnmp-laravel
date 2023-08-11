#!/bin/bash

_CHK_INF=`docker network ls | grep project-bridge`
if [ -z "$_CHK_INF" ]; then
  docker network create project-bridge
else
  echo "project-bridge already exist."
fi

if [ -z "./docker-compose.yml" ]; then
  echo "please rewrite docker-compose-example.yml to docker-compose.yml"
  exit 1
else
  docker-compose -f docker-compose.yml up -d
  sleep 1
  echo "======================"
  docker-compose -f docker-compose.yml ps
fi
