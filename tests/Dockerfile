FROM ubuntu:18.04

COPY ./tests.sh /tmp/

WORKDIR /tmp

# safe to pass env vars here because this image is not hosted on docker hub
CMD ["sh", "-c", "/tmp/tests.sh ${EMAIL} ${URL} ${SUBDOMAINS}"]