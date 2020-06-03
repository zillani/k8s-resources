# Cluster Maintenance
## Table of Contents
1. [Upgrade](#Upgrade)
2. [Maintenance](#Maintenance)
	1. [Draining a node](#Draining-a-node)
	2. [Cordoning a node](#Cordoning-a-node)
	3. [Marking node schedule/unschedule](#Marking-node-schedule/unschedule)
3. [Adding new node](#Adding-new-node)
4. [Bootstrap new control plane node](#Bootstrap-new-control-plane-node)
	1. [Using existing certs](#using-existing-certs)
	2. [Using regenerated certs](#using-regenerated-certs)
	3. [ETCD backup and restore](#etcd-backup-and-restore)



## Upgrade


### Upgrade kubeadm on master node
Make sure nodes are ready, upgrading from 1.15 to 1.16

```bash
apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.16.0-00 && \
apt-mark hold kubeadm
```

#### update kubectl & kubelt

```bash
kubectl drain master1 --ignore-daemonsets
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.16.0-00 kubectl=1.16.0-00 && \
apt-mark hold kubelet kubectl
kubectl get nodes
systemctl status kubelet
```

#### uncordon master

```bash
kubectl uncordon master1
```

### Upgrade kubeadm on worker node

APPLY SAME STEPS AS FOR THE MASTER NODE 


