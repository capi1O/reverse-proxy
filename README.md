docker HTTPS nginx reverse-proxy setup

# overview


- nginx reverse proxy docker
	- docker container A
	- docker container B
	- docker container C


The nginx reverse proxy docker manage HTTPS and redirect requests to correct docker containers based on hostname. It uses [lets-encrypt docker image](https://github.com/linuxserver/docker-letsencrypt)

# dependencies

- [docker](https://github.com/docker/docker-ce). for ubuntu : `curl -s https://gist.githubusercontent.com/monkeydri/43c7533b4c3b854495416a1e607fc5bf/raw/c814934ff15fba474f38fb41e52285c056169ef0/docker-setup.sh | bash`
- [docker-compose](https://github.com/docker/compose). for ubuntu : `curl -s https://gist.githubusercontent.com/monkeydri/3c1c89d3c51d1692ef4df409ff6dc0d0/raw/ec34d23cd8bc1616157aad64714150ff719a9c10/docker-compose-setup.sh | bash`

# quickstart

- create directory where all docker config files will be stored : `mkdir dockers`
- `git clone git@github.com/monkeydri/docker-https-nginx-reverse-proxy.git reverse-proxy && cd reverse-proxy`
- edit .env to fill required env vars
	- EMAIL: admin email (ex : `URL=admin@domain.com`)
	- URL : domain name (ex : `URL=domain.com`)
	- SUBDOMAINS : comma-separted list of subdomains (ex : `SUBDOMAINS=www,ftp`)
- make sure the host running the let's encrypt docker is reachable on ports 80 & 443 (ex: redirect ports on router) and that every subdomain DNS records points to its WAN IP.
- run setup script `chmod +x setup.sh && ./setup.sh`

# add a new service (docker container running behind the reverse-proxy)

base setup : docker-compose.yml for each service are placed in respective directories inside a dir named `dockers`

- dockers/
	- reverse-proxy/
		- [docker-compose.yml](docker-compose.yml)
		- config <= folder containing required configuration files and generated SSL certificates
		- nginx.conf <= shortcut to lets-encrypt internal conf file
	- service-A/
		- docker-compose.yml
		- conf-files...
	- service-B/
		- docker-compose.yml
	- ...

- put the docker-compose.yml file in dockers/new-docker/

```yml
version: '2'

services:
  new-service:
    image: some/docker:1.2.3
    restart: unless-stopped
    volumes:
    - ${PWD}/conf-file.conf:/path/to/conf-file.conf
    networks:
    - letsencrypt_nginx-net
networks:
  letsencrypt_nginx-net:
    external: true
```


- add a block at the end of the lets-encrypt docker nginx conf file `nginx.conf`

template block :

```conf
{
	# new-service
	server
	{
		listen 443 ssl;

		root /config/www;
		index index.html index.htm index.php;

		server_name subdomain.domain.com;

		# all ssl related config moved to ssl.conf
		include /config/nginx/ssl.conf;

		client_max_body_size 0;

		location / {
			proxy_pass							http://new-service;

			proxy_read_timeout      300;
			proxy_connect_timeout   300;
			proxy_redirect          off;

			proxy_set_header        X-Forwarded-Proto $scheme;
			proxy_set_header        Host              $http_host;
			proxy_set_header        X-Real-IP         $remote_addr;
			proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
			proxy_set_header        X-Forwarded-Proto https;
			proxy_set_header        X-Frame-Options   SAMEORIGIN;
			# proxy_set_header X-Forwarded-Ssl on; # uncomment if 422 HTTP Error on POST request

			access_log /var/log/nginx/access.log;
			error_log /var/log/nginx/error.log;
		}
	}
}
```

replace the lines `server_name subdomain.domain.com;` and `proxy_pass http://new-service;` where new-service corresponds to the name of the service in docker-compose.yml.

- start the new-service docker container `cd ./new-service && docker-compose up -d`

- restart lets'encrypt docker nginx service : `cd ./lets-encrypt && docker-compose exec -it lets-encrypt s6-svc -h /var/run/s6/services/nginx`

# ready to deploy services

- [gitlab-server](https://github.com/monkeydri/gitlab-server)
- [seafile-server](https://github.com/monkeydri/seafile-server)

# tests [![Build Status](https://img.shields.io/docker/cloud/build/monkeydri/reverse-proxy.svg?style=flat-square)](https://hub.docker.com/r/monkeydri/reverse-proxy)

## toolchain

This setup is run inside a [docker container](https://hub.docker.com/r/monkeydri/reverse-proxy) running ubuntu 18.04 on docker hub.

Using a docker container and docker hub automated build with autotests is a cheap and simple alternative to running a full VM (ex with circle-CI) to test the setup.

The [reverse-proxy](https://hub.docker.com/r/monkeydri/reverse-proxy) docker image is build on docker hub on each push and afterwards tests are run on it via another sut container : [docker-compose.tests.yml](docker-compose.tests.yml).

## build

The [Dockerfile](Dockerfile) builds a container which runs the setup and also additional test services. **It is not meant to be used for other purposes than testing**.

To build it manually : `docker build . -t monkeydri/reverse-proxy`.

Then run it with required env vars : `docker run --rm --env-file=.env -it monkeydri/reverse-proxy bash`. To override entrypoint : `docker run --rm --env-file=.env --entrypoint="/bin/sh" -it monkeydri/reverse-proxy -c /home/user/dockers/reverse-proxy/setup.sh`.

## connect the docker container to the world

[serveo](https://serveo.net/) is used to proxy let's encrypt bot requests to the test container.

- generate SSH key pair
- add an A record subdomain.domain.com => 159.89.214.31 (serveo.net)
- add a TXT record authkeyfp=[fingerprint] where fingerprint is the SSH key fingerprint (ssh-keygen -l)

source : https://serveo.net/

## setup [build env vars in docker hub](https://docs.docker.com/docker-hub/builds/#environment-variables-for-builds)

- EMAIL=admin@domain.com
- URL=domain.com
- SUBDOMAINS=subdomain
- SSH_PUBLIC_KEY=
- SSH_PRIVATE_KEY=

where SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa_serveo.pub) <= path to previsouly generated SSH public key
and SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa_serveo) <= path to previsouly generated SSH private key

/!\ the private key is multiline so to use it in an env file or on docker hub it must be escaped : `printf %q $SSH_PRIVATE_KEY`.

Those env vars are passed to the [reverse-proxy](https://hub.docker.com/r/monkeydri/reverse-proxy) container so it can connect to serveo on a custom domain.

## tests actually run (see [tests.sh](tests/tests.sh))

- [x] docker reachability on WAN (on test port 7357)
- [ ] SSL certificates generation
- [ ] service reachability behind the reverse-proxy
- [ ] email reception

# sources

- https://blog.linuxserver.io/2017/11/28/how-to-setup-a-reverse-proxy-with-letsencrypt-ssl-for-all-your-docker-apps/
- https://github.com/linuxserver/docker-letsencrypt/issues/71
- https://www.digitalocean.com/community/tutorials/how-to-use-netcat-to-establish-and-test-tcp-and-udp-connections-on-a-vps + https://serverfault.com/questions/346481/echo-server-with-netcat-or-socat