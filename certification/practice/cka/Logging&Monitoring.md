# Logging/Monitoring (5%)

## Understand how to monitor all cluster components

<details><summary>show</summary>
<p>

```bash
git clone https://github.com/kubernetes-incubator/metrics-server.git
kubectl creare -f deploy/1.8+/
kubectl top node
kubectl top pod
```

</p>
</details>

### Understand how to monitor applications

<details><summary>show</summary>
<p>

Create a YAML:

```bash
cat exec-liveness.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

```yaml
cat exec-readyness.yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

</p>
</details>

### Manage cluster component logs

<details><summary>show</summary>
<p>

```bash

containerised components log under /var/log

Master (/var/log or /var/log/containers)
       /var/log/kube-apiserver.log – API Server, responsible for serving the API
       /var/log/kube-scheduler.log – Scheduler, responsible for making scheduling decisions
       /var/log/kube-controller-manager.log – Controller that manages replication controllers

Worker Nodes (/var/log or /var/log/containers)
                /var/log/kubelet.log – Kubelet, responsible for running containers on the node
                /var/log/kube-proxy.log – Kube Proxy, responsible for service load balancing
```

</p>
</details>

### Manage application logs

<details><summary>show</summary>
<p>


```bash
docker run kodecloud/event-simulator
docker run -d kodecloud/event-simulator
docker logs -f ecf
```

```yaml
cat event-simulator.yaml

apiVersion: v1
kind: Pod
metadata:
  name: event-pod
spec:
  containers:
  - image: kodecloud/event-simulator
    name: event-simulator
  - image: nginx
    name: nginx
```

```bash
kubectl create -f event-simulator.yaml
kubectl logs -f event-pod
kubectl logs -f event-pod event-simulator

```

</p>
</details>
