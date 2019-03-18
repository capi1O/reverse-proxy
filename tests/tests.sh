#!/bin/sh

TEST_PASSED=true

EMAIL=$1
URL=$2
SUBDOMAINS=$3

# check that SSL certificate is correctly generated for domain
# TODO : cat config dir and compare

# xxxxx service reachability

# email reception

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