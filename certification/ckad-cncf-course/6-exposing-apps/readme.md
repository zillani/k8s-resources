# Exposing applications

## Table of Contents
1. [Service](#Service)
   1. [Service Diagram](#Service-Diagram)
   2. [Service Update Pattern](#Service-Update-Pattern)
   3. [Access Application as Service](#Access-Application-as-Service)
   4. [Service without a Selector](#Service-without-a-Selector)
   5. [clusterIp](#clusterIp)
   6. [NodePort](#NodePort)
   7. [LoadBalancer](#LoadBalancer)
   8. [ExternalName](#ExternalName)
2. [Ingress](#Ingress)
   1. [Ingress-Resource](#Ingress-Resource)
   2. [Ingress-Controller](#Ingress-Controller)
3. [Service Mesh](#Service-Mesh)
   1. [Istio](#Istio)
   2. [Linkerd](#Linkerd)
   3. [Envoy](#Envoy)
   4. [Control Plane vs Data Plane](#Control-Plane-vs-Data-Plane)

## Service

Service can be exposed in three ways,

- ClusterIP
- NodePort
- LoadBalancer
- ExternalName

_Note: ClusterIp is the default service type_

A newer service is ExternalName, which is a bit different. It has no selectors, nor does it define ports or endpoints. It allows the return of an alias to an external service. The redirection happens at the DNS level, not via a proxy or forward. This object can be useful for services not yet brought into the Kubernetes cluster. A simple change of the type in the future would redirect traffic to the internal objects

The `kubectl proxy` command creates a local service to access a __ClusterIP__
This can be useful for troubleshooting or development work

```bash
kubectl create -f service.yaml
```

### Service Diagram

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/services-diagram.jpg)


The __kube-proxy__ running on cluster nodes watches the API server service resources. It presents a type of virtual IP address for services other than __ExternalName__. The mode for this process has changed over versions of Kubernetes. 

In `v1.0`, services ran in userspace mode as `TCP/UDP` over `IP` or Layer 4.

In the `v1.1` release, the iptables proxy was added and became the default mode starting with `v1.2`. 

In the iptables proxy mode, kube-proxy continues to monitor the API server for changes in Service and Endpoint objects, and updates rules for each object when created or removed. One limitation to the new mode is an inability to connect to a Pod should the original request fail, so it uses a Readiness Probe to ensure all containers are functional prior to connection. This mode allows for up to approximately 5000 nodes. Assuming multiple Services and Pods per node, this leads to a bottleneck in the kernel.

Another mode beginning in `v1.9` is __ipvs__. While in beta, and expected to change, it works in the kernel space for greater speed, and allows for a configurable load-balancing algorithm, such as round-robin, shortest expected delay, least connection and several others. This can be helpful for large clusters, much past the previous 5000 node limitation. This mode assumes IPVS kernel modules are installed and running prior to kube-proxy. 
The kube-proxy mode is configured via a flag sent during initialization, such as __mode=iptables__ and could also be __IPVS__ or __userspace__. 

### Service Update Pattern

_Labels_ are used to determine which Pods should receive traffic from a service. Labels can be dynamically updated for an object, which may affect which Pods continue to connect to a service. 

The default update pattern is for a rolling deployment, where new Pods are added, with different versions of an application, and due to automatic load balancing, receive traffic along with previous versions of the application. 

Should there be a difference in applications deployed, such that clients would have issues communicating with different versions, you may consider a more specific label for the deployment, which includes a version number. When the deployment creates a new replication controller for the update, the label would not match. Once the new Pods have been created, and perhaps allowed to fully initialize, we would edit the labels for which the Service connects. Traffic would shift to the new and ready version, minimizing client version confusion

### Access Application as Service

The basic step to access a new service is to use `kubectl`	 

```bash
kubectl expose deployment/nginx --port=80 --type=NodePort 
kubectl get svc nginx -o yaml
```

```bash
apiVersion: v1 
kind: Service 
... 
spec: 
    clusterIP: 10.0.0.112 
    ports:     
    - nodePort: 31230 
...
```

Open browser `http://<Public IP>:31230`

### Service without a Selector 

Typically, a service creates a new endpoint for connectivity. Should you want to create the service, but later add the endpoint, such as connecting to a remote database, you can use a service without selectors. This can also be used to direct the service to another service, in a different namespace or cluster.

### NodePort

__NodePort__ is a simple connection from a high-port routed to a ClusterIP using iptables, or ipvs in newer versions. The creation of a NodePort generates a __ClusterIP__ by default. Traffic is routed from the __NodePort__ to the __ClusterIP__. Only high ports can be used, as declared in the source code. The NodePort is accessible via calls to `<NodeIP>:<NodePort>`

```bash
spec:
  clusterIP: 10.97.191.46
  externalTrafficPolicy: Cluster
  ports:
  - nodePort: 31070
    port: 80
    protocol: TCP
    targetPort: 800a0
  selector:
    io.kompose.service: nginx
  sessionAffinity: None
  type: NodePort
```

### LoadBalancer

Creating a LoadBalancer service generates a NodePort, which then creates a ClusterIP. It also sends an asynchronous call to an external load balancer, typically supplied by a cloud provider. The __External-IP__ value will remain in a __<Pending>__ state until the load balancer returns. Should it not return, the NodePort created acts as it would otherwise. 

```bash
Type: LoadBalancer
loadBalancerIP: 12.45.105.12
clusterIP: 10.5.31.33
ports:
- protocol: TCP
  Port: 80
```
The routing of traffic to a particular backend pod depends on the cloud provider in use

### ExternalName

The use of an _ExternalName_ service, which is a special type of service without selectors, is to point to an external DNS server. Use of the service returns a _CNAME_ record. Working with the _ExternalName_ service is handy when using a resource external to the cluster, perhaps prior to full integration.

```bash
spec:
  Type: ExternalName
  externalName: ext.db.example.com
``` 

## Ingress

### Ingress Resource

An ingress resource is an API object containing a list of rules matched against all incoming requests. Only HTTP rules are currently supported. In order for the controller to direct traffic to the backend, the HTTP request must match both the host and the path declared in the ingress

### Ingress Controller

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/ingress-controller.jpg)

Handling a few services can be easily done. However, managing thousands or tens of thousands of services can create inefficiencies. The use of an Ingress Controller manages ingress rules to route traffic to existing services. Ingress can be used for fan out to services, name-based hosting, TLS, or load balancing. Another feature is the ability to expose low-numbered ports. Services have been hard-coded not to expose ports lower than __1024__

There are a few Ingress Controllers with nginx and GCE that are "officially supported" by the community. 
Traefik (pronounced "traffic") and HAProxy are in common use, as well. More controllers are planned, as is support for more HTTPS/TLS modes, combining L4 and L7 ingress and requesting name or IP via claims.


If you have large number of services to be exposed outside the cluster, you need ingress. 
we are using traefic ingress because it's easier than nginx & GCE. 

```bash
kubectl create -f ingress-rbac.yaml
wget https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-ds.yaml
```
After downloading the traefik, remove the `securityContext` config and add `hostNetwork: true`

```bash
kubectl create -f traefik-ds.yaml
```
Now, ingest a ingress rule,

```bash
kubectl create -f ingress.rule.yaml
ip a
curl -H "Host: www.example.com" http://10.128.0.11"
```
Also try using the nodes' public ip

```bash
curl -H "Host: www.example.com" http://35.193.3.179
```

Create the third page app, 

```bash
kubectl run thirdpage --generator=run-pod/v1 --image=nginx --port=80 -l example=third
kubectl expose pod thirdpage --type=NodePort
kubectl exec -it thirdpage -- /bin/bash
```
After shell into the container, edit the nginx title
```bash
apt-get update
apt-get install vim -y
vim /usr/share/nginx/html/index.html
```
Now edit the ingress rule, update the host to thirdpage.org
```bash
kubectl edit ingress ingress-test
curl -H "Host: thirdpage.org" http://10.128.0.7/
```

## Service Mesh

A service mesh consists of edge and embedded proxies communicating with each other and handing traffic based on rules from a control plane.
For more complex connections or resources such as __service discovery__, __rate limiting__, __traffic management__ and __advanced metrics__ you may want to implement a service mesh.

### Istio

A powerful tool set which leverages Envoy proxies via a multi-component control plane.

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/istio-arch.jpg)

### Linkerd

An easy to deploy, fast, and ultralight service mesh.
Linkerd has default __linkerd2-proxy__ (aka linkerd-proxy) in it's dataplane.
Can be configured to use __Envoy__ proxy also.

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/linkerd2-arch.jpg)


### Envoy
Envoy is a proxy, not service mesh. Both linkerd & istio can be configured to use envoy proxy. 


### Control Plane vs Data Plane

- __The Control Plane__ responsibility is to manage and configure the sidecar proxies to enforce policies and collect telemetry.
- __The Data Plane__ responsibility is to handle the communication between the services and take care of the functionalities like Service Discovery, Load Balancing, Traffic Management, Health Check, etc

