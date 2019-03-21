FROM ubuntu:18.04

# install required dependencies
RUN apt-get update && apt install -y curl sudo nmap openssh-client

# sudo without password
USER root
COPY ./sudoers /etc/sudoers
RUN chmod 440 /etc/sudoers

# configure remote logging service
RUN curl -O https://www.loggly.com/install/configure-linux.sh && chmod +x configure-linux.sh
RUN sudo bash configure-linux.sh -a LOGGLY_SUBDOMAIN -u LOGGLY_USERNAME

# setup standard user UID:1000, GID:1000, home at /home/user
RUN groupadd -r group -g 1000 && useradd -u 1000 -r -g group -m -d /home/user -s /sbin/nologin -c "User" user && chmod 755 /home/user
USER user

# setup directories structure
RUN mkdir -p /home/user/dockers/reverse-proxy
WORKDIR /home/user/dockers/reverse-proxy

# install docker
RUN curl -s https://gist.githubusercontent.com/monkeydri/43c7533b4c3b854495416a1e607fc5bf/raw/a4dfdb647e7753fd475350dfd588d3706de5c872/docker-setup.sh | bash

# install docker-compose
RUN curl -s https://gist.githubusercontent.com/monkeydri/3c1c89d3c51d1692ef4df409ff6dc0d0/raw/ec34d23cd8bc1616157aad64714150ff719a9c10/docker-compose-setup.sh | bash

# Authorize serveo SSH Host (required for testing)
RUN mkdir -p /home/user/.ssh && chmod 0700 /home/user/.ssh && ssh-keyscan serveo.net > /home/user/.ssh/known_hosts

# copy docker files
COPY ./docker-compose.yml ./setup.sh /home/user/dockers/reverse-proxy/

CMD ["sh", "-c", "/home/user/dockers/reverse-proxy/setup.sh ${EMAIL} ${URL} ${SUBDOMAINS} ${TEST_MODE} ${SSH_PUBLIC_KEY} ${SSH_PRIVATE_KEY}"]
