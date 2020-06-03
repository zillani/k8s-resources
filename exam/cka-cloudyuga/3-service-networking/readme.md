# Service Networking
## Table of Contents
1. [CNI](#CNI)
2. [Services](#services)
	1. [ClusterIp](#ClusterIp)
	2. [NodePort](#NodePort)
	3. [LoadBalancer](#LoadBalancer)
3. [DNS](#DNS)
4. [Ingress](#Ingress)


## CNI

Container Network Interface

#### Installation

Install CNI & Plugins

```bash
mkdir ~/cni
mkdir ~/cni/plugins
mkdir ~/cni/net.d
wget https://github.com/containernetworking/cni/releases/download/v0.6.0/cni-amd64-v0.6.0.tgz && tar -xvf cni-amd64-v0.6.0.tgz -C ~/cni/. && rm cni-amd64-v0.6.0.tgz
wget https://github.com/containernetworking/plugins/releases/download/v0.7.4/cni-plugins-amd64-v0.7.4.tgz && tar -xvf cni-plugins-amd64-v0.7.4.tgz -C ~/cni/plugins/. && rm cni-plugins-amd64-v0.7.4.tgz
ls ~/cni/cnitool
ls ~/cni/plugins
tree ~/cni

```

#### Create container with --network=none

```bash
docker container run -d --name=web1 --network=none nginx:alpine
docker container exec web1 ifconfig
```
#### Create mynet configuration

```bash
cat > ~/cni/net.d/10-mynet.conf <<EOF
{
    "cniVersion": "0.3.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "10.22.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ]
    }
}
EOF
```

#### Attach IP to container

```bash
cd ~/cni
docker inspect web1 | jq .[0].NetworkSettings.SandboxKey | tr -d '"'
sudo CNI_PATH=~/cni/plugins  NETCONFPATH=~/cni/net.d \
./cnitool add mynet                 \
(docker inspect web1 |jq .[0].NetworkSettings.SandboxKey | tr -d '"')
docker container exec web1 ifconfig
```


## build local docker registry

#### docker-compose and R[[[](http://)](http://)](http://)egistry
```
apt-get install docker-compose apache2-utils
mkdir -p /localdocker/data
cd /localdocker/
docker-compose up
curl http://localhost:5000/v2/ #don't forget / in the end```


#### install kompose
```bash
curl -L https://github.com/kubernetes/kompose/releases/download/v1.19.0/kompose-linux-amd64 -o kompose
chmod +x kompose
mv kompose /usr/local/bin
```

