FROM ubuntu:18.04

RUN apt-get update && apt install -y curl sudo

# setup standard user UID:1000, GID:1000, home at /home/user
RUN groupadd -r group -g 1000 && useradd -u 1000 -r -g group -m -d /home/user -s /sbin/nologin -c "User" user && chmod 755 /home/user
USER user

# setup directories structure
RUN mkdir -p /home/user/dockers/reverse-proxy
WORKDIR /home/user/dockers/reverse-proxy

# install docker
RUN curl -s https://gist.githubusercontent.com/monkeydri/43c7533b4c3b854495416a1e607fc5bf/raw/c814934ff15fba474f38fb41e52285c056169ef0/docker-setup.sh | bash

# install docker-compose
RUN curl -s https://gist.githubusercontent.com/monkeydri/3c1c89d3c51d1692ef4df409ff6dc0d0/raw/ec34d23cd8bc1616157aad64714150ff719a9c10/docker-compose-setup.sh | bash

# copy docker files
COPY .docker-compose.yml .env .setup.sh /home/user/dockers/reverse-proxy/

EXPOSE 80 443

CMD ["/usr/bin/bash", "./setup.sh"]