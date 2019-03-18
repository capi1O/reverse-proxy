#!/bin/bash

# get env vars from args or .env file (.env file can be mounted at docker-compose.yml level when running this image)
source .env
EMAIL=${1:-"${EMAIL}"}
URL=${2:-"${URL}"}
SUBDOMAINS=${3:-"${SUBDOMAINS}"}
TEST_MODE=${4:-"${TEST_MODE}"}
SSH_PUBLIC_KEY=${5:-"${SSH_PUBLIC_KEY}"}
SSH_PRIVATE_KEY=${6:-"${SSH_PRIVATE_KEY}"}

# establish a SSH tunnel to serveo => will listen on WAN to redirect all incoming traffic to container (so it can receive SSL certificate challenges)
if [$TEST_MODE]; then
	# add the SSH key pair
	echo "$SSH_PRIVATE_KEY" > /home/user/.ssh/id_rsa && \
	echo "$SSH_PUBLIC_KEY" > /home/user/.ssh/id_rsa.pub && \
	chmod 600 /home/user/.ssh/id_rsa && \
	chmod 600 /home/user/.ssh/id_rsa.pub


	# establish a SSH proxy for every sudomain
	IFS=', ' read -r -a subdomains <<< "${SUBDOMAINS}"
	for SUBDOMAIN in "${subdomains[@]}"
	do
		ssh -R ${SUBDOMAIN}.${URL}:80:localhost:80 -R ${SUBDOMAIN}.${URL}:443:localhost:443 serveo.net
	done
fi

# create docker network
docker network create letsencrypt_nginx-net

# start the container
EMAIL=$EMAIL URL=$URL SUBDOMAINS=$SUBDOMAINS docker-compose up -d

# create a shortcut to the main nginx conf file
ln -s config/nginx/site-confs/default ./nginx.conf