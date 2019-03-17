#!/bin/bash

# /!\ fill required env vars in .env files before running this script

# create docker network
docker network create letsencrypt_nginx-net

# start the container
docker-compose up -d

# create a shortcut to the main nginx conf file
ln -s config/nginx/site-confs/default ./nginx.conf