#!/bin/bash

function check_env_vars ()
{
	ENV_VARS=("$@")
	for ENV_VAR in "${ENV_VARS[@]}"; do
		if ! [[ -v $ENV_VAR ]]; then
			echo -e "\\e[91mrequired env var $ENV_VAR is not defined"
			exit 1
		fi
	done
}

# output > syslog
exec 1> >(logger -s -t $(basename $0)) 2>&1

# check that all required env vars are set
REQUIRED_ENV_VARS=("EMAIL" "URL" "SUBDOMAINS")
check_env_vars "${REQUIRED_ENV_VARS[@]}"

REACHABILITY_OUTPUT="REVERSE-PROXY-REACHABLE"

# create directory structure and download required files
mkdir -p dockers/reverse-proxy
cd dockers/reverse-proxy && \
curl -O https://raw.githubusercontent.com/monkeydri/reverse-proxy/master/docker-compose.yml

# establish a SSH tunnel to serveo => will listen on WAN to redirect all incoming traffic to container (so it can receive SSL certificate challenges)
if [ $TEST_MODE ]; then

	# check that all required test env vars are set
	REQUIRED_TEST_ENV_VARS=("SSH_PUBLIC_KEY" "SSH_PRIVATE_KEY" "TIMBER_API_KEY" "TIMBER_SOURCE_ID")
	check_env_vars "${REQUIRED_ENV_VARS[@]}"

	# setup fluent bit => Timber
	curl -s https://raw.githubusercontent.com/monkeydri/ubuntu-server-scripts/master/setup-fluentbit-timber.sh | TIMBER_API_KEY=${TIMBER_API_KEY} TIMBER_SOURCE_ID=${TIMBER_SOURCE_ID} HOSTNAME="reverse-proxy-vm-${URL}" bash

	# unescape SSH private key
	UNESCAPED_SSH_PRIVATE_KEY=$(echo $SSH_PRIVATE_KEY)

	# start a service listening on 7357 for reachability test
	nohup ncat -e "/bin/echo ${REACHABILITY_OUTPUT}" -k -l 7357 &

	# add the SSH key pair
	echo "$UNESCAPED_SSH_PRIVATE_KEY" > /home/user/.ssh/id_rsa && \
	echo "$SSH_PUBLIC_KEY" > /home/user/.ssh/id_rsa.pub && \
	chmod 600 /home/user/.ssh/id_rsa && \
	chmod 600 /home/user/.ssh/id_rsa.pub

	# establish a SSH proxy for every sudomain
	IFS=', ' read -r -a subdomains <<< "${SUBDOMAINS}"
	for SUBDOMAIN in "${subdomains[@]}"; do
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