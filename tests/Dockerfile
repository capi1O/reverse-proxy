FROM ubuntu:18.04

RUN apt-get update && apt install -y nmap

COPY ./tests.sh /tmp/

WORKDIR /tmp 

ARG EMAIL
ENV EMAIL $EMAIL
ARG URL
ENV URL $URL
ARG SUBDOMAINS
ENV SUBDOMAINS $SUBDOMAINS

# safe to pass env vars here because this image is not hosted on docker hub
CMD ["sh", "-c", "/tmp/tests.sh ${EMAIL} ${URL} ${SUBDOMAINS}"]