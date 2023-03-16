#!/bin/bash
set -euv

sudo yum update -y
sudo amazon-linux-extras install docker -y && sudo service docker start
#usermod -a -G docker ec2-user
sudo curl -L https://github.com/docker/compose/releases/download/2.16.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo mkdir -p /media/docker
sudo chown ec2-user:ec2-user /media/docker

# Gen pass:
#  - bcrypt encryption;
#  - batch mode (command line);
#  - results on standard output.
sudo docker run --rm httpd:alpine htpasswd -Bbn testuser testpasswd > /media/docker/nginx.htpasswd


# ------------------------------------------------------------------------------
# - Create docker network                                                      -
# ------------------------------------------------------------------------------

sudo docker network create --internal backend

# ------------------------------------------------------------------------------
# - PHP container                                                              -
# ------------------------------------------------------------------------------

# mv config
sudo mv /tmp/index.php /media/docker/index.php

sudo docker create \
 --user "$(id -u):$(id -g)" \
 --name php \
 --restart=on-failure:3 \
 --volume "/media/docker/index.php:/var/www/html/index.php:rw" \
php:fpm-alpine

sudo docker network connect backend php

sudo docker start php

# ------------------------------------------------------------------------------
# - Nginx container                                                            -
# ------------------------------------------------------------------------------

# mv config
sudo mv /tmp/default.conf /media/docker/default.conf

# Launch Docker
sudo docker create \
 --name nginx-proxy \
 --restart=on-failure:3 \
 --publish 80:80 \
--volume "/media/docker/nginx.htpasswd:/etc/nginx/nginx.htpasswd:ro" \
--volume "/media/docker/default.conf:/etc/nginx/conf.d/default.conf:ro" \
nginx:1.23-alpine

sudo docker network connect backend nginx-proxy

sudo docker start nginx-proxy
