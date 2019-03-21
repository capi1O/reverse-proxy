FROM ubuntu:18.04

# install required dependencies
RUN apt-get update && apt install -y curl sudo nmap openssh-client wget gnupg2

# sudo without password
USER root
COPY ./sudoers /etc/sudoers
RUN chmod 440 /etc/sudoers

# setup remote logging service
RUN curl -s https://raw.githubusercontent.com/monkeydri/ubuntu-server-scripts/master/setup-fluentbit.sh | bash

# setup standard user UID:1000, GID:1000, home at /home/user
RUN groupadd -r group -g 1000 && useradd -u 1000 -r -g group -m -d /home/user -s /sbin/nologin -c "User" user && chmod 755 /home/user
USER user

WORKDIR /home/user/

# install docker
RUN curl -s https://raw.githubusercontent.com/monkeydri/ubuntu-server-scripts/master/docker-setup.sh | bash

# install docker-compose
RUN curl -s https://raw.githubusercontent.com/monkeydri/ubuntu-server-scripts/master/docker-compose-setup.sh | bash

# Authorize serveo SSH Host
RUN mkdir -p /home/user/.ssh && chmod 0700 /home/user/.ssh && ssh-keyscan serveo.net > /home/user/.ssh/known_hosts

# copy docker files
COPY ./setup.sh /home/user/

CMD ["sh", "-c", "/home/user/setup.sh"]
