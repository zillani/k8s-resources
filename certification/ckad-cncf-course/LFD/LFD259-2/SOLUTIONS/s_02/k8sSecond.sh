#!/bin/bash
#/* **************** LFD259:2019-08-19 s_02/k8sSecond.sh **************** */
#/*
# * The code herein is: Copyright the Linux Foundation, 2019
# *
# * This Copyright is retained for the purpose of protecting free
# * redistribution of source.
# *
# *     URL:    https://training.linuxfoundation.org
# *     email:  training@linuxfoundation.org
# *
# * This code is distributed under Version 2 of the GNU General Public
# * License, which you should have received with the source.
# *
# */
#!/bin/bash -x
## TxS 8-2019
## CKAD for 1.15.1
##
echo "  This script is written to work with Ubuntu 16.04"
echo
sleep 3
echo "  Disable swap until next reboot"
echo
sudo swapoff -a

echo "  Update the local node"
sleep 2
sudo apt-get update && sudo apt-get upgrade -y
echo
sleep 2

echo "  Install Docker"
sleep 3
sudo apt-get install -y docker.io

echo
echo "  Install kubeadm and kubectl"
sleep 2
sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"

sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"

sudo apt-get update

sudo apt-get install -y kubeadm=1.15.1-00 kubelet=1.15.1-00 kubectl=1.15.1-00

echo
echo "  Script finished. You now need the kubeadm join command"
echo "  from the output on the master node"
echo 

