FROM ubuntu:18.04

RUN apt-get update && apt install -y curl nmap

# sudo without password
USER root
COPY ./sudoers /etc/sudoers
RUN chmod 440 /etc/sudoers

# configure remote logging service
RUN curl -O https://www.loggly.com/install/configure-linux.sh && chmod +x configure-linux.sh
RUN sudo bash configure-linux.sh -a LOGGLY_SUBDOMAIN -u LOGGLY_USERNAME

COPY ./tests.sh /tmp/

WORKDIR /tmp 

# safe to pass env vars here because this image is not hosted on docker hub
CMD ["sh", "-c", "/tmp/tests.sh ${EMAIL} ${URL} ${SUBDOMAINS}"]