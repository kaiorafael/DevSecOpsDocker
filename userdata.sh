#!/bin/bash
yum update -y
yum install git -y
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
cd /home/ec2-user && git clone https://github.com/kaiorafael/DevSecOpsDocker.git
chown -R ec2-user:ec2-user /home/ec2-user
cd /home/ec2-user/DevSecOpsDocker/Docker && docker-compose up -d