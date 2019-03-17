docker HTTPS nginx reverse-proxy

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
- make sure the host running the let's encrypt docker is reachable on ports 80 & 443 (redirect ports on router)
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

# sources

- https://blog.linuxserver.io/2017/11/28/how-to-setup-a-reverse-proxy-with-letsencrypt-ssl-for-all-your-docker-apps/
- https://github.com/linuxserver/docker-letsencrypt/issues/71