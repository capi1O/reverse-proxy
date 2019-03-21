#!/bin/bash

ALL_TESTS_PASSED=true

# TODO : check required env vars are all set
# REQUIRED_ENV_VARS=[EMAIL, URL, SUBDOMAINS]

REACHABILITY_OUTPUT="REVERSE-PROXY-REACHABLE"

# 1. reverse-proxy container reachability - try to reach it on SUBDOMAINS[0].URL:7357, compare output with desired output
# netcat listening on 7357 on reverse-proxy docker, with SSH tunnel setup on port 7357 to serveo.net + A record setup on subdomain.
IFS=', ' read -r -a subdomains <<< "${SUBDOMAINS}"
for SUBDOMAIN in "${subdomains[@]}"
do
	OUTPUT=$(ncat ${SUBDOMAIN}.${URL} 7357)
	if [ "$OUTPUT" == "$REACHABILITY_OUTPUT" ]; then
		echo -e "\\e[92m${SUBDOMAIN}.${URL} reachable"
	else
		echo -e "\\e[91m${SUBDOMAIN}.${URL} not reachable"
		ALL_TESTS_PASSED=false
	fi
done


# 2. test SSL certificate generation for each subdomain
# TODO : cat config dir and compare
# check the logs of nginx-revserse-proxy

# 3. test service (behind reverse-proxy) reachability
# add dummy service(nginx or apache docker) and try to reach it on SUBDOMAINS.URL, compare output with desired output

# 4. email reception

# 5. test shortcut creation

if [ "$ALL_TESTS_PASSED" = true ]; then
	echo -e "\\e[42m------------"
	echo -e "\\e[92mAll tests passed"
	echo -e "\\e[42m------------"
	exit 0
else
	echo -e "\\e[41m------------"
	echo -e "\\e[91mSome test failed"
	echo -e "\\e[41m------------"
	exit 1
fi