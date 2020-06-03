# Architecture

1. [Architecture](#Architecture)
2. [Networking](#Networking)
   1. [Ingress](#Ingress)
   2. [Calico](#Calico)
   3. [CNI](#CNI)
3. [Installation](#Installation)
4. [Uninstall](#Uninstall)
5. [Upgrade](#Upgrade)
   1. [Upgrade master node](#Upgrade-master-node)
   2. [Upgrade worker node](#Upgrade-worker-node)
   3. [Errors](#Errors)
6. [Downgrade](#Downgrade)
7. [Taint Master](#Taint-Master)
8. [Deploy](#Deploy)
   1. [Basic Pod](#Basic-Pod)
   2. [Expose Service](#Expose-Service)
   3. [Multi-Container Pods](#Multi-Container-Pods)
   4. [Basic Deployment](#Basic-Deployment)
   5. [Basic Commands](#Basic-Commands)


## Architecture

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/k8s-arch.png)

- __kube-apiserver__: An agent
- __etcd__: stores cluster state (b-tree key-value)

- __kube-scheduler__: Sees request coming to API & finds suitable node to run container
- __kubelet__: The HEAVY LIFTER, accepts request for PodSpec (Json/Yaml) & manages resources
               & watches over them
- __kubeproxy__: Manages n/w rules & expose container on network

_note:_ from 1.15.1 multi-master is possible using stacked etcd or external database cluster

- __kube-controller-manager__: If state of cluster doesn't match the desired state, then it will 
							   controllers to match the desired state

## Networking

Pod is a co-located containers which share same IPAddress

Three communication challenges,
| Problem        | Solved by  |
| -------------  |:---------: |
| Coupled container-to-container | Pod Concept |
| Pod-to-Pod | Networking Config |
| External-to-Pod | Ingress |


### Ingress
Ingress controller or ServiceMesh (ISTIO, Linkerd) can be used to connect external traffic to pod.

Logger Pod: Sidecar for logging & writing to database
Pause Pod: To Retrieve namespace & IpAddress

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/k8s-nw.jpg)

### Calico
Observe Calico pods running on BIRD protocol
![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/k8s-calico.jpg)

### CNI

## Installation
- Install vmware 
- Install 3 ubuntu servers 18.x (say, ubuntu1, ubuntu2, ubuntu3)
- ubuntu1 is master node and its should have 2 vCPUs, other can have 1vCPU
- Install k8s components on master node using this script, `k8sMaster.sh`
- once the installation is done, in the end you can find the output command generated
- For worker nodes, use `k8sSecond.sh`
- Copy the command generated on master node and exectue the command on worker node
- After the installation is complete, you can ssh into the master node and access the cluster, 
  OR you can copy the config located at `/etc/kubernetes/admin.conf`

_note_: If you are accessing the cluster after restarting the nodes, please turn off swap
`sudo swapoff -a`


## Uninstall k8s

Perform the below commands on master & worker node,
```bash
rm -rf ~/.kube
kubeadm reset
```

## Upgrade
You can use the script `upgradeMaster.sh` or follow steps below,

__Conditions__

- swap must be off `sudo swapoff -a`
- CANNOT SKIP MINOR VERSIONS
  you can upgrade from 1.15.x to 1.16.x, but not from 1.15.x to 1.17.x

### Upgrade master node

__Find the version available__

```bash
apt update
apt-cache madison kubeadm
```

__Install the version desired__

```bash
apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.16.6-00 --allow-downgrades && \
apt-mark hold kubeadm
```

note: you can get `connection-timeout` issue while upgrading,
just update namerserver and continue.

verify & drain the node, 
below, `ubuntu1` is the name of master node,

```bash
kubeadm version
kubectl drain ubuntu1 --ignore-daemonsets
kubectl drain ubuntu2 --ignore-daemonsets
kubectl drain ubuntu3 --ignore-daemonsets
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.16.6 --force
```

__Update kubectl & kubelet__
```bash
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.16.6-00 kubectl=1.16.6-00 && \
apt-mark hold kubelet kubectl
```

__Restart kubelet__
```bash
sudo systemctl restart kubelet
```

__Uncordon the node__
```bash
kubectl uncordon ubuntu1
```

### Upgrade worker node

You can use the script `upgradeWorker.sh` or follow steps below,

__Upgrade kubeadm__
```bash
apt-mark unhold kubeadm && \
apt-get update && apt-get install -y kubeadm=1.16.6-00 --allow-downgrades && \
apt-mark hold kubeadm
```
__Drain node, (from master node)__
```bash
kubectl drain ubuntu2 --ignore-daemonsets
```
__Upgrade node__
```bash
sudo kubeadm upgrade node
```

__Update kubectl & kubelet__
```bash
apt-mark unhold kubelet kubectl && \
apt-get update && apt-get install -y kubelet=1.16.6-00 kubectl=1.16.6-00 && \
apt-mark hold kubelet kubectl
```

__Restart kubelet__
```bash
sudo systemctl restart kubelet
```

__Uncordon the node, (from master/w-node)__
```bash
kubectl uncordon ubuntu2
```

### Errors
Error with pre-flight checks, ignore them,
```bash
sudo kubeadm upgrade apply v1.16.6 --ignore-preflight-errors all
```

Error while draining, 
Reset the config file & try again.

```bash
rm ~/.kube/config
cat /etc/kubernetes/admin.conf > ~/.kube/config
```

note: if something goes wrong, you can uncordon the master node, 
```bash
kubectl uncordon ubuntu1
```

## Downgrade

Follow same steps as above, with the flags below,
```bash
rm -rf /usr/bin/kubeadm
apt-get update
apt-get install
sudo apt-get install -y kubeadm=1.15.9-00 kubelet=1.15.9-00 kubectl=1.15.9-00 --allow-downgrades --allow-change-held-packages
```

## Taint Master

Let's first add bash completion for `kubectl` 
```bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```
By default the master node will not allow general containers to be deployed for security reasons. This is via a taint. Only containers which tolerate this taint will be scheduled on this node. 

Let's try to remove the taint on master node, 

```bash
kubectl describe nodes | grep -i Taint
```
copy the taint name and untaint it, 
Please note that you need to suffix with `-`

```bash
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
kubectl describe nodes | grep -i taint
```

## Deploy

### Basic Pod

```bash
kubectl create -f basic.yaml
kubectl get pod -o wide
curl localhost
kubectl delete pod basicpod
```

### Expose Service

```bash
kubectl delete -f basic.yaml
kubectl create -f basic-final.yaml
kubectl create -f basic-service.yaml
```
verify the service, 

```bash
curl <private-ip>
```

change the service type to `ClusterIp` and redeploy, 
now you should be able to access it using the nodes' public ip & port

```bash
curl http://35.238.3.83:31514
```

### Multi-Container Pods

_Using a single container per pod allows for the most granularity and decoupling. There are still some reasons to deploy multiple containers, sometimes called composite containers, in a single pod. The secondary containers can handle logging or enhance the primary, the sidecar concept, or acting as a proxy to the outside, the ambassador concept, or modifyingdatatomeetanexternalformatsuchasan adapter. Allthreeconceptsaresecondarycontainerstoperform a function the primary container does not_

```bash
kubectl apply -f basic-later.yaml
```

### Basic Deployment

```bash
kubectl create deployment my-nginx --image=nginx
kubectl describe deployment my-nginx
kubectl describe pod my-nginx-64bb...
kubectl get deployment my-nginx -oyaml --export > my-nginx.yaml
```

### Basic Commands

```bash
kubectl get pod --all-namespaces
kubectl get pod -n kube-system
kubectl get deploy, rs, rc, po, svc, ep
kubectl delete deployment my-nginx
```
