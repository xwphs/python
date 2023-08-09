#!/usr/bin/env bash

mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
