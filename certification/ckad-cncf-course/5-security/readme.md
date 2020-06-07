# Security
## Table of Contents
1. [Security](#Security)
   1. [Authentication](#Authentication)
   2. [Authorization](#Authorization)
   3. [ABAC](#ABAC)
   4. [RBAC](#RBAC)
   5. [RBAC Process Flow](#RBAC-Process-Flow)
   6. [Admission Controller](#Admission-Controller)
2. [SecurityContext](#SecurityContext)
   1. [Pod Security Policy](#Pod-Security-Policy)
   2. [Example](#Example)
3. [Consuming Secrets](#Consuming-Secrets)
4. [ServiceAccounts](#ServiceAccounts)
5. [NetworkPolicy](#NetworkPolicy)
   1. [Network Policy with ingress and egress](#Network-Policy-with-ingress-and-egress)
   2. [Network Policy with ipBlock](#Network-Policy-with-ipBlock)


## Security

To perform any action in a Kubernetes cluster, you need to access the API and go through three main steps:

- Authentication
- Authorization (ABAC or RBAC)
- Admission Control

![](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/api-access-flow-k8s.jpg)

Once a request reaches the API server securely, it will first go through any __authentication__ module that has been configured.
At the authorization step, the request will be checked against existing __policies__. It will be authorized if the user has the permissions to perform the requested actions. Then, the requests will go through the last step of __admission__. 

In general, admission controllers will check the actual content of the objects being created and validate them before admitting the request. 
In addition to these steps, the requests reaching the API server over the network are encrypted using TLS. This needs to be properly configured using SSL certificates. 

Follow [Kelsey Hightower's guide - Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) 
if you use kubeadm for this configuration.

### Authentication

Authentication is done with `certificates`, `tokens` or `basic authentication` (i.e. username and password).

Users are not created by the API, but should be managed by an external system.

System accounts are used by processes to access the API.

There are two more advanced authentication mechanisms: 
__Webhooks__ Used to verify bearer tokens
__OpenID__ A External connection provider

The type of authentication used is defined in the __kube-apiserver__ startup options. 

Below are four examples of a subset of configuration options that would need to be set depending on what choice of authentication mechanism you choose:

```bash
--basic-auth-file 
--oidc-issuer-url
--token-auth-file 
--authorization-webhook-config-file
```

One or more Authenticator Modules are used: `x509 Client Certs`; `static token`, `bearer` or `bootstrap token`; `static password file`; `service account` and `OpenID connect tokens` 

Each is tried until successful, and the order is not guaranteed. Anonymous access can also be enabled, otherwise you will get a `401 response`.

### Authorization

Once a request is authenticated, it needs to be authorized.

There are three main authorization modes and two global Deny/Allow settings. The three main modes are:
- __ABAC__
- __RBAC__
- __WebHook__

They can be configured as kube-apiserver startup options:

```bash
--authorization-mode=ABAC 
--authorization-mode=RBAC 
--authorization-mode=Webhook 
--authorization-mode=AlwaysDeny 
--authorization-mode=AlwaysAllow
```

The authorization modes implement policies to allow requests. Attributes of the requests are checked against the policies (e.g. user, group, namespace, verb).


### ABAC

__ABAC__ stands for __Attribute Based Access Control__. 
It was the first authorization model in Kubernetes that allowed administrators to implement the right policies. Today, RBAC is becoming the default authorization mode.
Policies are defined in a JSON file and referenced to by a __kube-apiserver__ startup option:
`--authorization-policy-file=my_policy.json`

For example, the policy file shown below authorizes user Bob to read pods in the namespace foobar:

```bash
{ 
    "apiVersion": "abac.authorization.kubernetes.io/v1beta1", 
    "kind": "Policy", 
    "spec": { 
        "user": "bob", 
        "namespace": "foobar", 
        "resource": "pods", 
        "readonly": true     
    } 
}
```
### RBAC

__RBAC__ stands for __Role Based Access Control__

All resources are modeled API objects in Kubernetes, from Pods to Namespaces. They also belong to API Groups, such as __core__ and __apps__. 

These resources allow operations such as Create, Read, Update, and Delete (CRUD), which we have been working with so far. Operations are called __verbs__ inside YAML files. Adding to these basic components, we will add more elements of the API, which can then be managed via RBAC. 
__Rules__ are operations which can act upon an API group. 
__Roles__ are a group of rules which affect, or scope, a single namespace.
__ClusterRoles__ have a scope of the entire cluster. 

Each operation can act upon one of three subjects, which are __User Accounts__ which don't exist as __API objects__, __Service Accounts__, and __Groups__ which are known as __clusterrolebinding__ when using kubectl. 
RBAC is then writing rules to allow or deny operations by users, roles or groups upon resources

### RBAC Process Flow

While RBAC can be complex, the basic flow is to create a certificate for a user. As a user is not an API object of Kubernetes, we are requiring outside authentication, such as OpenSSL certificates. After generating the certificate against the cluster certificate authority, we can set that credential for the user using a __context__. 
Roles can then be used to configure an association of __apiGroups__, __resources__, and the __verbs__ allowed to them. The user can then be bound to a role limiting what and where they can work in the cluster. 

Here is a summary of the RBAC process:
- Determine or create namespace
- Create certificate credentials for user
- Set the credentials for the user to the namespace using a context
- Create a role for the expected task set
- Bind the user to the role
- Verify the user has limited access.

### Admission Controller

The last step in letting an API request into Kubernetes is admission control.
__Admission controllers__ are pieces of software that can access the content of the objects being created by the requests. They can modify the content or validate it, and potentially deny the request.

Admission controllers are needed for certain features to work properly. Controllers have been added as Kubernetes matured. Starting with the 1.13.1 release of the kube-apiserver, the admission controllers are now compiled into the binary, instead of a list passed during execution. To enable or disable, you can pass the following options, changing out the plugins you want to enable or disable:
```bash
--enable-admission-plugins=Initializers,NamespaceLifecycle,LimitRanger
--disable-admission-plugins=PodNodeSelector
```

The first controller is __Initializers__ which will allow the dynamic modification of the API request, providing great flexibility. Each admission controller functionality is explained in the documentation. For example, the __ResourceQuota__ controller will ensure that the object created does not violate any of the existing quotas.

## SecurityContext

Pods and containers within pods can be given specific security constraints to limit what processes running in containers can do. For example, the UID of the process, the Linux capabilities, and the filesystem group can be limited.
This security limitation is called a `security context`. It can be defined for the entire pod or per container, and is represented as additional sections in the resources manifests. The notable difference is that Linux capabilities are set at the container level.
For example, if you want to enforce a policy that containers cannot run their process as the root user, you can add a pod security context like the one below:

```bash
apiVersion: v1 
kind: Pod 
metadata: 
  name: nginx 
spec: 
  securityContext: 
    runAsNonRoot: true 
  containers: 
  - image: nginx 
    name: nginx
```

Then, when you create this pod, you will see a warning that the container is trying to run as root and that it is not allowed. Hence, the Pod will never run:

```bash
$ kubectl get pods
NAME   READY  STATUS                                                 RESTARTS  AGE
nginx  0/1    container has runAsNonRoot and image will run as root  0         10s 
```

### Pod Security Policy

To enforce security context you need Pod Security Policy, (PSP)
These policies are cluster-level rules that govern what a pod can do, what they can access, what user they run as, etc. 
For instance, if you do not want any of the containers in your cluster to run as the root user, you can define a PSP to that effect. You can also prevent containers from being privileged or use the host network namespace, or the host PID namespace.

You can see an example of a PSP below:

```bash
apiVersion: extensions/v1beta1 
kind: PodSecurityPolicy 
metadata: 
  name: restricted 
spec: 
  seLinux: 
    rule: RunAsAny 
  supplementalGroups: 
    rule: RunAsAny 
  runAsUser: 
    rule: MustRunAsNonRoot 
  fsGroup: 
    rule: RunAsAny
```

For Pod Security Policies to be enabled, you need to configure the admission controller of the controller-manager to contain `PodSecurityPolicy`. These policies make even more sense when coupled with the RBAC configuration in your cluster. This will allow you to finely tune what your users are allowed to run and what capabilities and low level privileges their containers will have. 

[PSP RBAC example](https://github.com/kubernetes/examples/blob/master/staging/podsecuritypolicy/rbac/README.md)


### Example

```bash
kubectl create -f second.yaml
kubectl exec -it secondApp -- sh
ps aux
grep Cap /proc/1/status
capsh --decode=00000000a80425fb
```
read more about kernel capabilities here, https://github.com/torvalds/linux/blob/master/include/uapi/linux/capability.h

Now, delete the pod & edit the second.yaml & add new capabilities, 

```bash
add: [ "NET_ADMIN" , "SYS_TIME" ]
```
Setting NET ADMIN to allow interface, routing, and other network conﬁguration. 
Setting SYS TIME, allows system clock conﬁguration.

Now, create the pod again & check Cap settings

```bash
kubectl create -f second.yaml
kubectl exec -it secondapp -- sh
grep Cap /proc/1/status
capsh --decode=00000000aa0435fb
```
You will observe that new capabilities are added.

## Consuming Secrets

```bash
echo "batman" |base64
YmF0bWFuCg==
kubectl create -f secret-second.yaml
kubectl exec -it secondapp -- /bin/sh
cat /mysqlpassword/password
cd /mysqlpassword
ls -lah
```
note that password file is a symbolic link to `data`


## ServiceAccounts

We can use ServiceAccounts to assign cluster roles, or the ability to use particular HTTP verbs. In this section we will create a new ServiceAccount and grant it access to view secrets.

```bash
kubectl create -f serviceaccount.yaml
kubectl get clusterroles

kubectl get clusterroles admin -o yaml <output_omitted>
kubectl get clusterroles cluster-admin -o yaml
```

From output above create your own file, 

```bash
kubectl create -f cluster-role.yaml
```
Now, Let's bind the role to the account,

```bash
kubectl create -f rolebinding.yaml
```

check sa for our `secondapp`

```bash
kubectl describe pod secondapp |grep -i secret
```

Edit our deployment, 

```bash
vim second.yaml
```

like below,

```bash
   name: secondapp
spec:
  serviceAccountName: secret-access-sa #<-- Add this line
  securityContext:
    runAsUser: 1000
```
Delete this pod & redeploy again and see the `sa`

```bash
kubectl describe pod secondapp |grep -i secret
```

## NetworkPolicy

By default, all pods can reach each other; all ingress and egress traffic is allowed. This has been a high-level networking requirement in Kubernetes. However, network isolation can be configured and traffic to pods can be blocked. In newer versions of Kubernetes, egress traffic can also be blocked. This is done by configuring a __NetworkPolicy__. 

As all traffic is allowed, you may want to implement a policy that drops all traffic, then, other policies which allow desired ingress and egress traffic. 
The spec of the policy can narrow down the effect to a particular namespace, which can be handy. Further settings include a `podSelector`, or `label`, to narrow down which Pods are affected. Further ingress and egress settings declare traffic to and from IP addresses and ports. 

Not all network providers support the `NetworkPolicies` kind. 
A non-exhaustive list of providers with support includes __Calico__, __Romana__, __Cilium__, __Kube-router__, and __WeaveNet__. 

In previous versions of Kubernetes, there was a requirement to annotate a namespace as part of network isolation, specifically the `net.beta.kubernetes.io/network-policy= value` 

Some network plugins may still require this setting. 

An early architecture decision with Kubernetes was non-isolation, that all pods were able to connect to all other pods and nodes by design. In more recent releases the use ofa NetworkPolicy allows for pod isolation. The policy only has effect when the networkplugin, like `ProjectCalico`, are capable of honoring them. If used with a plugin like `ﬂannel` they will have no effect. The use of matchLabels allows for more granular selection within the namespace which can be selected using a namespaceSelector. Using multiple labels can allow for complex application of rules. 

[network-policies](#https://kubernetes.io/docs/concepts/services-networking/network-policies)

### Network Policy sample

The use of policies has become stable, noted with the v1 apiVersion. The example below narrows down the policy to affect the default namespace. 
Only Pods with the label of __role: db__ will be affected by this policy, and the policy has both Ingress and Egress settings.
The ingress setting includes a __172.17__ network, with a smaller range of __172.17.1.0 IPs__ being excluded from this traffic. 

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-egress-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
  - namespaceSelector:
      matchLabels:
        project: myproject
  - podSelector:
      matchLabels:
        role: frontend
  ports:
  - protocol: TCP 
    port: 6379
egress:
- to:
  - ipBlock:
      cidr: 10.0.0.0/24
  ports:
  - protocol: TCP
    port: 5978 
```

These rules change the namespace for the following settings to be labeled `project: myproject`. The affected Pods also would need to match the label `role: frontend`. Finally, TCP traffic on port 6379 would be allowed from these Pods. 
The `egress` rules have the to settings, in this case the 10.0.0.0/24 range TCP traffic to port 5978.
The use of empty ingress or egress rules denies all type of traffic for the included Pods, though this is not suggested. Use another dedicated `NetworkPolicy` instead.
Note that there can also be complex `matchExpressions` statements in the spec, but this may change as `NetworkPolicy` matures. 

```bash
podSelector:
  matchExpressions:
    - {key: inns, operator: In, values: ["yes"]} 
```

### Network Policy Default

The empty braces will match all Pods not selected by other NetworkPolicy and will not allow ingress traffic. Egress traffic would be unaffected by this policy.

```bash
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress ​
```
With the potential for complex ingress and egress rules, it may be helpful to create multiple objects which include simple isolation rules and use easy to understand names and labels.

Some network plugins, such as __WeaveNet__, may require annotation of the Namespace. 
The following shows the setting of a __DefaultDeny__ for the __myns__ namespace: 

```bash
kind: Namespace
apiVersion: v1
metadata:
  name: myns
  annotations:
    net.beta.kubernetes.io/network-policy: |
     {
        "ingress": {
          "isolation": "DefaultDeny" 
        }
     }
```

### Network Policy with ingress and egress

Below app creates a policy that denies all traffic except from ingress/egress
```bash
kubectl create -f allclosed.yaml
```

Update `second.yaml` with the below config
```bash
containers: 
- name: webserver
  image: nginx 
- name: busy 
  image: busybox 
```
Observe the pod is failing `kubectl get event` , now remove the `securityContext` , add a label and deploy again, 
create the service to expose,

```bash
metadata: 
  name: secondapp 
  labels: 
    example: second
```

```bash
kubectl create service nodeport secondapp --tcp=80
```

Using this, edit to add the `selector` and a nodeport 

```bash
kubectl get svc secondapp -o yaml

```

```bash
...
ports:
- name: "80"
  nodePort: 32000
...
selector:
  example: second
```

Now test the service with nodeIp & clusterIP

Test ingress using node-ip & clusterIP with port,

```bash
curl <http://node-ip>
curl <clusterIP>:<nodePort>
```

Now test `egress` from container to oustide using `netcat`,

```bash
kubectl exec -it -c busy secondapp sh

nc -vz 127.0.0.1 80
127.0.0.1 (127.0.0.1:80) open
nc -vz www.linux.com 80
www.linux.com (151.101.185.5:80) open
exit
```

### Network Policy with ipBlock

Let's create a network policy that will allow to access the service
from private ipv4 16bit address like `192.168..`

- Test from your laptop `curl <nodeIp-public>:<nodePort>`
- Test from node `curl <nodeIp-private>`
- Test from container to external web by shelling into it & `netcat`

All of these will timeout,

__Let's Remove Egress and Add eth0__

Add below config to `allclosed.yaml`

```bash
 spec:
 podSelector: {} 
 policyTypes:
 - Ingress
 # - Egress
 
```

```bash
kubectl exec -it -c busy secondapp sh
nc -vz www.linux.com 80
www.linux.com (151.101.185.5:80) open
ip a
```
use the `eth0` range and update it as below,

```bash
policyTypes:
- Ingress 
ingress: #<-- Add this and following three lines 
- from:
  - ipBlock: 
      cidr: 192.168.0.0/16
# - Egress
```

Check the network policy, 
```bash
kubectl get network-policy
```

```bash
kubectl replace -f ~/allclosed.yaml

- Ingress 
ingress:
- from: 
  - ipBlock: 
      cidr: 192.168.0.0/16 
  ports: #<-- Add this and two following lines
  - port: 80 
    protocol: TCP 
# - Egres
```

```bash
kubectl replace -f allclosed.yaml
```

By adding the ip, you can access the service like, 

```bash
curl http://192.168.55.91
```

