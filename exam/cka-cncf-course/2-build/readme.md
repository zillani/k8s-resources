# Build
## Table of Contents
1. [Containers](#Containers)
   1. [Container Runtime Interface](#Container-Runtime-Interface)
   2. [CLI tools for Docker](#CLI-tools-for-Docker)
2. [Simple app](#simple-app)
3. [Configure local docker registry](#build-local-docker-registry)
	1. [docker-compose and registry](#docker-compose-and-registry)
	2. [Install kompose](#Install-kompose)
	3. [Create volumes](#Create-volumes)
	4. [Enable insecure access master node](#Enable-insecure-access-master-node)
	5. [Test local docker registry](#Test-local-docker-registry)
	6. [Enable insecure access worker node](#Enable-insecure-access-worker-node)
	7. [Export deployment](#Export-deployment)
4. [Configure Probes](#Configure-Probes)
	1. [Add readinessProbes](#Add-readinessProbes)
	2. [Add livenessProbes](#Add-livenessProbes)



_Note_: Here, `10.110.186.162` is the ipaddress of master node.

## Containers

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/vm-vs-container.jpg)

### Container Runtime Interface

Container runtime is the component which run the containerized apps, `Docker Engine` remains as default
for kubernetes.

Below are few alternatives for `docker`
- [cri-o](https://cri-o.io/)
- [containerd](https://containerd.io)
- [rktlet](https://github.com/kubernetes-retired/rktlet)
- [frakti](https://github.com/kubernetes/frakti)

### CLI tools for Docker

Docker has been standardized as the industry standard, below are some useful tools,
- [buildah](https://github.com/containers/buildah)
- [podman](https://podman.io/)


## Simple app

```bash
apt-get install python
docker build -t simpleapp .
find / -name date.out
```

## Configure local docker registry

Replace `10.110.186.162` with ipAddress of your master node

#### docker-compose and registry
```bash
apt-get install docker-compose apache2-utils
mkdir -p /localdocker/data
cd /localdocker/
docker-compose up
curl http://10.110.186.162:5000/v2/ #don't forget / in the end
```

#### Install kompose
```bash
curl -L https://github.com/kubernetes/kompose/releases/download/v1.19.0/kompose-linux-amd64 -o kompose
chmod +x kompose
mv kompose /usr/local/bin
```

#### Create volumes

```bash
kubectl create -f vol1.yaml
kubectl create -f vol2.yaml
cd /localdocker

kompose convert -f docker-compose.yaml -o localregistry.yaml
less localregistry.yaml
kubectl create -f localregistry.yaml
curl http://10.110.186.162:5000/v2/ #don't forget / in the end
```

#### Enable insecure access master node

Edit docker configuration to allow insecure access

```bash
sudo vim /etc/docker/daemon.json
```
add the ipaddress/localhost as in the previous curl command. 

```bash
{ "insecure-registries":["10.110.186.162:5000"}
```
Now, restart docker service, 

```bash
sudo systemctl restart docker.service
```

#### Test local docker registry

```bash
docker pull ubuntu
docker tag ubuntu:latest 10.110.186.162:5000/myubuntu
docker push 10.110.186.162:5000/myubuntu
```
Now, remove images & test it

```bash
docker image remove 10.110.186.162:5000/myubuntu
docker image remove myubuntu

docker pull 10.110.186.162:5000/myubuntu
docker tag simpleapp 10.110.186.162:5000/simpleapp
docker push simpleapp 10.110.186.162:5000/simpleapp
```

#### Enable insecure access worker node

Here, assuming `10.110.186.162` is the ip address of the master.
```bash
sudo vim /etc/docker/daemon.json

{ "insecure-registries":["10.110.186.162:5000"}

systemctl restart docker.service
docker pull 10.110.186.162:5000/simpleapp
kubectl create deployment try1 --image=10.110.186.162:5000/simpleapp:latest
kubectl scale deployment try1 --replicas=6

```

#### Export deployment
Now export the deployment to yaml file,
```bash

kubectl get deployment try1 -o yaml --export > simpleapp.yaml
kubectl delete deployment try1
kubectl create -f simpleapp.yaml

```

## Configure Probes

#### Add readinessProbes
edit simpleapp.yaml & add readiness probes,
```bash
readinessProbe:
  exec:
  command:
  - cat
  - /tmp/healthy
periodSeconds: 5
```

```bash
kubectl delete -f simpleapp.yaml
kubectl create -f simpleapp.yaml
kubectl exec -it simpleapp-9868b88-rtch -- /bin/bash
touch /tmp/healthy
exit
``` 

create /tmp/healthy on all six replicas,

```bash
for name in simpleapp-9869bdb88-2wfnr \
	simpleapp-9869bdb88-6bknl \
	simpleapp-9869bdb88-786v8 \
	simpleapp-9869bdb88-gmvs4 \
	simpleapp-9869bdb88-lfvlx
do 
kubectl exec $name touch /tmp/healthy
done
```
#### Add livenessProbes

```bash
vim simpleapp.yaml
```
Add liveness probes to simpleapp.yaml,
```bash
livenessProbe: 
  tcpSocket:
    port: 8080
initialDelaySeconds: 15
periodSeconds: 20
```
Re-create the deployment
```bash
kubectl delete deployment simpleapp
kubectl create -f simpleapp.yaml
```

```bash
for name in simpleapp-9869bdb88-2wfnr \
	simpleapp-9869bdb88-6bknl \
	simpleapp-9869bdb88-786v8 \
	simpleapp-9869bdb88-gmvs4 \
	simpleapp-9869bdb88-lfvlx
do 
kubectl exec $name touch /tmp/healthy
done
```

verify the pod

```bash
kubectl describe pod simpleapp-76cc5ffcc6-tx4dz | tail
kubectl describe pod simpleapp-76cc5ffcc6-tx4dz | grep -E 'State|Ready'
```
