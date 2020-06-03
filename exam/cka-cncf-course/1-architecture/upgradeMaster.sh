#!/bin/bash

VERSION=$1
VERSION_NAME=$2

apt update

apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm=$VERSION --allow-downgrades && apt-mark hold kubeadm

kubeadm version

kubectl drain ubuntu1 --ignore-daemonsets

kubectl drain ubuntu2 --ignore-daemonsets

kubectl drain ubuntu3 --ignore-daemonsets

sudo kubeadm upgrade plan

sudo kubeadm upgrade apply $VERSION_NAME --force

apt-mark unhold kubelet kubectl && \

apt-get update && apt-get install -y kubelet=$VERSION kubectl=$VERSION && \

apt-mark hold kubelet kubectl

sudo systemctl restart kubelet

kubectl uncordon ubuntu1
