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

# mv config
sudo mv /tmp/default.conf /media/docker/default.conf

# Launch Dosker
sudo docker run -d \
 --name nginx \
 --publish 80:80 \
`# --volume "/media/docker/nginx.htpasswd:/etc/nginx/nginx.htpasswd:ro"` \
`# --volume "/media/docker/default.conf:/etc/nginx/conf.d/default.conf:ro"` \
 --env TZ=Europe/Moscow \
nginx:1.23-alpine
