#!/bin/bash

# output > syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

# start logging service
sudo service td-agent-bit start

# get env vars from args - TODO : check required

EMAIL=$1
URL=$2
SUBDOMAINS=$3
TEST_MODE=$4
SSH_PUBLIC_KEY=$5
# unescape private key
ESCAPED_SSH_PRIVATE_KEY=$6
UNESCAPED_SSH_PRIVATE_KEY=$(echo $ESCAPED_SSH_PRIVATE_KEY)

REACHABILITY_OUTPUT="REVERSE-PROXY-REACHABLE"

# establish a SSH tunnel to serveo => will listen on WAN to redirect all incoming traffic to container (so it can receive SSL certificate challenges)
if [ $TEST_MODE ]; then

	# start a service listening on 7357 for reachability test
	nohup ncat -e "/bin/echo ${REACHABILITY_OUTPUT}" -k -l 7357 &

	# add the SSH key pair
	echo "$UNESCAPED_SSH_PRIVATE_KEY" > /home/user/.ssh/id_rsa && \
	echo "$SSH_PUBLIC_KEY" > /home/user/.ssh/id_rsa.pub && \
	chmod 600 /home/user/.ssh/id_rsa && \
	chmod 600 /home/user/.ssh/id_rsa.pub


	# establish a SSH proxy for every sudomain
	IFS=', ' read -r -a subdomains <<< "${SUBDOMAINS}"
	for SUBDOMAIN in "${subdomains[@]}"
	do
		nohup ssh -R ${SUBDOMAIN}.${URL}:7357:localhost:7357 -R ${SUBDOMAIN}.${URL}:80:localhost:80 -R ${SUBDOMAIN}.${URL}:443:localhost:443 serveo.net &
	done

	# 7357 : reachability test
	# test docker (sut) => subdomain.url:123 => serveo.net:123 <===ssh===> reverse-proxy (running on docker hub)

	# 80 : HTTP domain validation
	# let's encrypt bot => subdomain.url:80 => serveo.net:80 <===ssh===> reverse-proxy (running on docker hub)

	# 443 : HTTPS connection
	# client => subdomain.url:443 => serveo.net:443 <===ssh===> reverse-proxy (running on docker hub)

fi

# create docker network
docker network create letsencrypt_nginx-net

# start the container
EMAIL=$EMAIL URL=$URL SUBDOMAINS=$SUBDOMAINS docker-compose up -d

# create a shortcut to the main nginx conf file
ln -s config/nginx/site-confs/default ./nginx.conf