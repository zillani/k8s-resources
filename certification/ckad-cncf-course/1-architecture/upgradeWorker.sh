#!/bin/bash

VERSION=$1

apt-mark unhold kubeadm && apt-get update && apt-get install -y kubeadm=$VERSION --allow-downgrades && apt-mark hold kubeadm

sudo kubeadm upgrade node

apt-mark unhold kubelet kubectl && \

apt-get update && apt-get install -y kubelet=$VERSION kubectl=$VERSION && \

apt-mark hold kubelet kubectl

sudo systemctl restart kubelet

kubectl uncordon ubuntu2
