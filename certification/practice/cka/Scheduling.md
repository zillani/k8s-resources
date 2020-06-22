# Scheduling (5%)

## Scheduling


### Create 3 pods with names nginx1,nginx2,nginx3. All of them should have the label app=v1

<details><summary>show</summary>
<p>

```bash
kubectl run nginx1 --image=nginx --restart=Never --labels=app=v1
kubectl run nginx2 --image=nginx --restart=Never --labels=app=v1
kubectl run nginx3 --image=nginx --restart=Never --labels=app=v1
```

</p>
</details

### Create a deployment with image nginx:1.7.8, called nginx, having 2 replicas, defining port 80 as the port that this container exposes (don't create a service for this deployment)

<details><summary>show</summary>
<p>

```bash
kubectl run nginx --image=nginx:1.7.8 --replicas=2 --port=80
```

**However**, `kubectl run` for Deployments is Deprecated and will be removed in a future version. What you can do is:

```bash
kubectl create deployment nginx  --image=nginx:1.7.8  --dry-run -o yaml > deploy.yaml
vi deploy.yaml
# change the replicas field from 1 to 2
# add this section to the container spec and save the deploy.yaml file
# ports:
#   - containerPort: 80
kubectl apply -f deploy.yaml
```

### Use label selectors to schedule Pods

<details><summary>show</summary>
<p>

```bash
kubectl label nodes node-1 size=Large
```

</p>
</details>

### Understand how to run multiple schedulers and how to configure Pods to use them

<details><summary>show</summary>
<p>

```bash
cat schedulerpod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-custom-scheduler
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-scheduler
    - --address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scsheduler.conf
    - -- leader-elect=true
    - --lock-object-name=my-custom-scsheduler
    image: k8s.gcr.io/kube-scheduler-amd64:v1.11.3
    name: kube-scheduler
```

```yaml
cat pod-to-schedule-differently.yaml

apiVersion: v1
kind: Pod
metadata:
  name: my-custom-scheduled-pod
spec:
  containers:
  - image: nginx
    name: nginx
  schedulerName: my-custom-scheduled
```

</p>
</details>

### Manually schedule a Pod without a scheduler

<details><summary>show</summary>
<p>


Store the POD yaml files in `/etc/Kubernetes/manifests`

Create a static pod named static-busybox that uses the busybox image and the command sleep 1000

```bash
kubectl run static-busybox --image=busybox --restart=Never  --dry-run -o yaml --command -- sleep 1000 > /etc/kubernetes/manifests/static-busybox.yaml
```

If you are asked to delete a static Pod from a specific node then run,

```bash
kubectl get nodes -o wide
```

to get the Node IP and then ssh to it. 
Kubelet config file might be `/var/lib/kubelet/config.yaml`.
Check the 'staticPodPath:' and go to that directory and delete the YAML file.

</p>
</details>

### Display scheduler events

<details><summary>show</summary>
<p>

```bash
kubectl get events
kubectl get events --watch
kubectl logs kube-scheduler-bk8s-node0 -n kube-system

/var/log/kube-scheduler.log on the control/master node (if schedule is standalone service)
```

</p>
</details>

### Know how to configure the Kubernetes scheduler

<details><summary>show</summary>
<p>

```bash
wget "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler"

chmod +x kube-scheduler
sudo mv kube-scheduler /usr/local/bin/
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: componentconfig/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable kube-scheduler
sudo systemctl start kube-scheduler
```

</p>
</details>
