# Design

## Table of Contents

1. [Design Concerns](#Design-Concerns)
   1. [Decoupled resources](#Decoupled-resources)
   2. [Transience](#Transience)
   3. [Flexible](#Flexible)
   4. [Resources](#Resources)
      1. [CPU](#CPU)
      2. [RAM](#RAM)
      3. [Ephemeral storage](#Ephemeral-storage)
2. [Design Patterns](#Design-Patterns)
   1. [Sidecar Pattern](#Sidecar-Pattern)
   2. [Adapter Pattern](#Adapter-Pattern)
   3. [Ambassdor Pattern](#Ambassdor-Pattern)
3. [Using Label Selectors](#Using-Label-Selectors)
4. [Network Plugins](#Network-Plugins)
5. [CNI Providers](#CNI-Providers)
6. [Job](#Job)
   1. [completions](#completions)
   2. [parallelism](#parallelism)
   3. [activeDeadlineSeconds](#activeDeadlineSeconds)
7. [CronJob](#CronJob)

## Design Concerns

![jigsaw](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/jig-saw.jpg)

### Decoupled resources

Instead of hard-coding a resource in an application, an intermediary, such as a Service, enables connection and reconnection to other resources, providing flexibility. A single machine is no longer required to meet the application and user needs; any number of systems could be brought together to meet the needs when, and, as long as, necessary.

As Kubernetes grows, even more resources are being divided out, which allows for an easier deployment of resources. Also, Kubernetes developers can optimize a particular function with fewer considerations of others objects

### Transience

Each object should be developed with the expectation that other components will die and be rebuilt. With any and all resources planned for transient relationships to others, we can update versions or scale usage in an easy manner.

An upgrade is perhaps not quite the correct term, as the existing application does not survive. Instead, a controller terminates the container and deploys a new one to replace it, using a different version of the application or setting. Typically, traditional applications were not written this way, opting toward long-term relationships for efficiency and ease of use.

### Flexible

Like a school of fish, or pod of whales, multiple independent resources working together, but decoupled from each other and without expectation of individual permanent relationship, gain flexibility, higher availability and easy scalability.

Instead of a monolithic Apache server, we can deploy a flexible number of nginx servers, each handling a small part of the workload. The goal is the same, but the framework of the solution is distinct.  

A decoupled, flexible and transient application and framework is not the most efficient. In order for the Kubernetes orchestration to work, we need a series of agents, otherwise known as controllers or watch-loops, to constantly monitor the current cluster state and make changes until that state matches the declared configuration.

### Resources

Kubernetes allows us to easily scale clusters, larger or smaller, to meet demand.
The kube-scheduler, or a custom scheduler, uses the `PodSpec` to determine the best node for deployment.
In addition to administrative tasks to grow or shrink the cluster or the number of Pods, there are autoscalers which can add or remove nodes or pods, with plans for one which uses [cgroup](#https://sysadmincasts.com/episodes/14-introduction-to-linux-control-groups-cgroups) settings to limit CPU and memory usage by individual containers.

By default, Pods use as much CPU and memory as the workload requires, behaving and coexisting with other Linux processes. Through the use of resource requests, the scheduler will only schedule a Pod to a node if resources exist to meet all requests on that node. The scheduler takes these and several other factors into account when selecting a node for use.

Monitoring the resource usage cluster-wide is not an included feature of Kubernetes. Other projects, like Prometheus, are used instead.

### CPU

CPU requests are made in CPU units, each unit being a __millicore__, using __mille__ - the Latin word for thousand.
Some documentation uses __millicore__, others use __millicpu__, but both have the same meaning.  

#### Thus, a request for .7 of a CPU would be 700 milicore

Should a container use more resources than allowed, it won’t be killed. The exact amount of overuse is not definite. Note the notation often found in the documentation. Each dot would represent a new line and indent if converted to YAML.

```bash
spec.containers[].resources.limits.cpu
spec.containers[].resources.requests.cpu
```

The value of CPUs is not relative. It does not matter how many exist, or if other Pods have requirements.
One CPU, in Kubernetes, is equivalent to:

- 1 AWS vCPU
- 1 GCP Core
- 1 Azure vCore
- 1 Hyperthread on a bare-metal Intel processor with Hyperthreading.

### RAM

With Docker engine, the limits.memory value is converted to an integer value and becomes the value to the command,
`docker run --memory <value> <image>`
The handling of a container which exceeds its memory limit is not definite.
It may be restarted, or, if it asks for more than the memory request setting, the entire Pod may be evicted from the node.

```bash
spec.containers[].resources.limits.memory
spec.containers[].resources.requests.memory
```

### Ephemeral storage

#### Feature state: 1.17 beta

Container files, logs, and EmptyDir storage, as well as Kubernetes cluster data, reside on the root filesystem of the host node.
As storage is a limited resource, you may need to manage it as other resources.

The scheduler will only choose a node with enough space to meet the sum of all the container requests.
Should a particular container, or the sum of the containers in a Pod, use more than the limit, the Pod will be evicted.

```bash
spec.containers[].resources.limits.ephemeral-storage
spec.containers[].resources.requests.ephemeral-storage
```

## Design Patterns

[kubernetes patterns](https://www.weave.works/blog/container-design-patterns-for-kubernetes/)

### Sidecar Pattern

From the idea of decouping design, rather than bloating code, which may not be necessary in other deployments, adding a container to handle a function such as logging solves the issue, while remaining decoupled and scalable.
Prometheus monitoring and Fluentd logging leverage sidecar containers to collect data.

![sidecar-pattern](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/sidecar-pattern.jpg)

### Adapter Pattern

The basic purpose of an adapter container is to modify data, either on ingress or egress, to match some other need.
Perhaps, an existing enterprise-wide monitoring tools has particular data format needs.
An adapter would be an efficient way to standardize the output of the main container to be ingested by the monitoring tool, without having to modify the monitor or the containerized application.

![adapter-pattern](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/adapter-pattern.jpg)

### Ambassdor Pattern

[Ambassador](https://www.getambassador.io/) is an "open source, Kubernetes-native API gateway for microservices.

An ambassador allows for access to the outside world without having to implement a service or another entry in an ingress controller:

- Proxy local connection
- Reverse proxy
- Limits HTTP requests
Re-route from the main container to the outside world.​

![ambassdor-pattern](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/ambassdor-pattern.jpg)

## Using Label Selectors

Labels allow for objects to be selected, which may not share other characteristics.
Consider the possible ways you may want to group your pods and other objects in production.
Perhaps you may use development and production labels to differentiate the state of the application. Perhaps you may want to add labels for the department, team, and primary application developer.

Selectors are namespace-scoped. Use the `--all-namespaces` argument to select matching objects in all namespaces.
The labels, annotations, name, and metadata of an object can be found near the top of

```bash
kubectl get pod examplepod-1234-vtlzd -o yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    cni.projectcalico.org/podIP: 192.168.113.220/32
  generateName: examplepod-1234-
  labels:
    app: examplepod
    pod-template-hash: 1234
  name: examplepod-1234-vtlzd
```

We can get a pod using the `--selector` flag
In the command line, the colon(:) would be replaced with an equals (=) sign and the space removed.
The use of `-l` or `--selector` options can be used with kubectl.

```bash
kubectl -n test2 get --selector app=examplepod pod
NAME       READY  STATUS   RESTARTS  AGE
examplepod 1/1    Running  0         25m
```

## Network Plugins

```bash
ps -ef | grep cni
sudo find / -name install-cni.sh
sudo less \ /var/lib/docker/aufs/diff/a7cd14de39089493b793f135ec965f0f3f79eeec8f9d78e679d7be1a3bdf3345/install-cni.sh
```

## CNI Providers

- [Project Calico](https://docs.projectcalico.org/v3.0/introduction/ )
- [Calico with Canal](https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal )
- [Weave Works](https://www.weave.works/docs/net/latest/kubernetes/kube-addon)
- [Flannel](https://github.com/coreos/flannel )
- [Romana](http://romana.io/how/romana_basics/ )
- [Kube Router](https://www.kube-router.io )
- [Kopeio](https://github.com/kopeio/networking)

- __Which of the plugins allow vxlans?__
  Canal, Flannel, Kopeio-networking, Weave Net
- __Which are layer 2 plugins?__
  Canal, Flannel, Kopeio-networking, Weave Net
- __Which are layer 3?__
  Project Calico, Romana, Kube Router
- __Which allow network policies?__
  Project Calico, Canal, Kube Router, Romana Weave Net
- __Which can encrypt all TCP and UDP trafﬁc?__
  Project Calico, Kopeio, Weave Net

## Multi Container Pods

- __Which deployment method would allow the most ﬂexibility, multiple applications per pod or one per Pod?__
   One per pod
- __Which deployment method allows for the most granular scalability?__
   One per pod
- __Which have the best inter-container performance?__
   Multiple per pod.
- __How many IP addresses are assigned per pod?__
   One
- __What are some ways containers can communicate within the same pod?__
   IPC, loopback or shared ﬁlesystem access.
- __What are some reasons you should have multiple containers per pod?__
   Lean containers may not have functionality like logging. Able to maintain lean execution but add functionality as necessary, like Ambassadors and Sidecar containers.

## Job

```bash
kubectl create -f job.yaml
kubectl describe jobs.batch sleepy
kubectl get job
kubectl get jobs.batch sleepy -o yaml
kubectl delete jobs.batch sleepy
```

### completions

```bash
spec:
  completions: 5
```

```bash
kubectl create -f job.yaml
kubectl get jobs.batch
```

### parallelism

To execute jobs in parallel,

add below line just under completion,

```bash
parallelism: 2
```

```bash
kubectl delete -f job.yaml
kubectl create -f job.yaml
watch kubectk get jobs
```

### activeDeadlineSeconds

add the following section under parrallelism,

```bash
activeDeadlineSeconds: 15
```

This will end the job forcibly if the job failed to finish under the deadline.

### CronJob

Please note that apiVersion is `apiVersion: batch/v1beta1`

Remove parallelism, completions & activeDeadlineSeconds

```bash
 schedule: "*/2 * * * *
```

Test, you can observe that jobs are created after every two minutes.

```bash
kubectl create -f cronjob.yaml
```
