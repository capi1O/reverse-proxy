FROM ubuntu:18.04

# setup directories structure
RUN mkdir -p /tmp/dockers/reverse-proxy
WORKDIR /tmp/dockers/reverse-proxy

RUN apt-get update && apt install -y curl

# install docker
RUN curl -s https://gist.githubusercontent.com/monkeydri/43c7533b4c3b854495416a1e607fc5bf/raw/c814934ff15fba474f38fb41e52285c056169ef0/docker-setup.sh | bash

# install docker-compose
RUN curl -s https://gist.githubusercontent.com/monkeydri/3c1c89d3c51d1692ef4df409ff6dc0d0/raw/ec34d23cd8bc1616157aad64714150ff719a9c10/docker-compose-setup.sh | bash

# copy docker files
COPY .docker-compose.yml .env .setup.sh /tmp/dockers/reverse-proxy/

EXPOSE 80 443

CMD ["/usr/bin/bash", "./setup.sh"]