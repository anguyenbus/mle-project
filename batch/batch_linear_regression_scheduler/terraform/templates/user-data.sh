#!/bin/bash

# Install SSM
sudo yum install -y https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm

# Install AWS Inspector
curl -Lo /tmp/aws_inspector_install https://inspector-agent.amazonaws.com/linux/latest/install
chmod +x /tmp/aws_inspector_install
sudo bash /tmp/aws_inspector_install
rm -rf /tmp/aws_inspector_install

# ECS config
{
  echo "ECS_CLUSTER=${cluster_name}"
} >> /etc/ecs/ecs.config

start ecs

echo "Done"
