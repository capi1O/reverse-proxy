#!/bin/sh

TEST_PASSED=true

EMAIL=$1
URL=$2
SUBDOMAINS=$3

# 1. xxxxx reverse-proxy container reachability
# launch web server (nginx or apache docker) on reverse-proxy docker and try to reach it on SUBDOMAINS[0].URL, compare output with dessired output

# 2. test SSL certificate generation for each subdomain
# TODO : cat config dir and compare

# 3. test service (behind reverse-proxy) reachability
# add dummy service(nginx or apache docker) and try to reach it on SUBDOMAINS.URL, compare output with desired output

# 4. email reception

if [ "$TEST_PASSED" = true ] ; then
  echo -e "\\e[42m------------"
  echo -e "\\e[92mTests passed"
  echo -e "\\e[42m------------"
  exit 0
else
  echo -e "\\e[41m------------"
  echo -e "\\e[91mTests failed"
  echo -e "\\e[41m------------"
  exit 1
fi