FROM ubuntu:18.04

# install required dependencies
RUN apt-get update && apt install -y curl wget sudo nmap openssh-client gnupg2

# sudo without password
USER root
COPY ./sudoers /etc/sudoers
RUN chmod 440 /etc/sudoers

# setup remote logging service TODO : run from bash script
RUN wget -qO - https://packages.fluentbit.io/fluentbit.key | sudo apt-key add -
RUN sudo bash -c "echo 'deb https://packages.fluentbit.io/ubuntu/bionic bionic main' >> /etc/apt/sources.list"
RUN apt-get update && apt install -y td-agent-bit

# setup standard user UID:1000, GID:1000, home at /home/user
RUN groupadd -r group -g 1000 && useradd -u 1000 -r -g group -m -d /home/user -s /sbin/nologin -c "User" user && chmod 755 /home/user
USER user

WORKDIR /home/user/

# install docker
RUN curl -s https://gist.githubusercontent.com/monkeydri/43c7533b4c3b854495416a1e607fc5bf/raw/a4dfdb647e7753fd475350dfd588d3706de5c872/docker-setup.sh | bash

# install docker-compose
RUN curl -s https://gist.githubusercontent.com/monkeydri/3c1c89d3c51d1692ef4df409ff6dc0d0/raw/ec34d23cd8bc1616157aad64714150ff719a9c10/docker-compose-setup.sh | bash

# Authorize serveo SSH Host
RUN mkdir -p /home/user/.ssh && chmod 0700 /home/user/.ssh && ssh-keyscan serveo.net > /home/user/.ssh/known_hosts

# copy docker files
COPY ./setup.sh /home/user/

CMD ["sh", "-c", "/home/user/setup.sh"]
