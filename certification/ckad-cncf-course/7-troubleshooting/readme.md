# Troubleshooting

1. [Troubleshoot Applications](#Troubleshoot-Applications)
   1. [Node and Security](#Node-and-Security)
   2. [Agents](#Agents)
   3. [Monitoring](#Monitoring)
   4. [Logging](#Logging)
   5. [Monitoring Applications](#Monitoring-Applications)
   6. [Check Pod event](#Check-Pod-event)
   7. [Check Container logs](#Check-Container-logs)
   8. [Check DNS](#Check-DNS)
   9. [Check Service and Endpoint](#Check-Service-and-Endpoint)
   10. [Check kube-proxy](#Check-kube-proxy)
2. [Conformance Testing](Conformance-Testing)

## Troubleshoot Applications

```bash
kubectl create deployment troubleshoot --image=nginx
kubectl exec -ti troubleshoot-<tab> -- /bin/sh
```

The issues found with a decoupled system like Kubernetes are similar to those of a traditional datacenter, plus the added layers of Kubernetes controllers:

- __Errors from the command line__
- __Pod logs and state of Pods__
- __Use shell to troubleshoot Pod DNS and network__
- __Check node logs for errors, make sure there are enough resources allocated__
- __RBAC, SELinux or AppArmor for security settings​__
- __API calls to and from controllers to kube-apiserver__
- __Inter-node network issues, DNS and firewall__
- __Master server controllers (control Pods in pending or error state, errors in log files, sufficient resources, etc)__

### Node and Security

Disabling security for testing would be a common response to an issue. Each tool has its own logs and indications of rule violation. There could be multiple issues to troubleshoot, so be sure to re-enable security and test the workload again.
Internode networking can also be an issue. Changes to switches, routes, or other network settings can adversely affect Kubernetes. Historically, the primary causes were DNS and firewalls. As Kubernetes integrations have become more common and DNS integration is maturing, this has become less of an issue. Still, check connectivity and for recent infrastructure changes as part of your troubleshooting process. Every so often, an update which was said shouldn’t cause an issue may, in fact, be causing an issue

### Agents

The issues found with a decoupled system like Kubernetes are similar to those of a traditional datacenter, plus the added layers of Kubernetes controllers:

- Control pods in pending or error state
- Look for errors in log files
- Are there enough resources? etc.​

### Monitoring

Monitoring is about collecting metrics from the infrastructure, as well as applications.
__Prometheus__ is part of the Cloud Native Computing Foundation (CNCF). As a Kubernetes plugin, it allows one to scrape resource usage metrics from Kubernetes objects across the entire cluster. It also has several client libraries which allow you to instrument your application code in order to collect application level metrics.

Collecting metrics is the first step, making use of the data collected is the next. We have the ability to expose lots of data points. Graphing the data with a tool like __Grafana__ can allow for visual understanding of the cluster and application status. Some facilities fill walls with large TVs offering the entire company a real-time view of demand and utilization.

### Logging

Logging, like monitoring, is a vast subject in IT. It has many tools that you can use as part of your arsenal.
Typically, logs are collected locally and aggregated before being ingested by a search engine and displayed via a dashboard which can use the search syntax.
While there are many software stacks that you can use for logging, the __Elasticsearch__, __Logstash__, and __Kibana Stack (ELK)__ has become quite common.

In Kubernetes, the __kubelet__ writes container logs to local files (via the Docker logging driver).
The kubectl logs command allows you to retrieve these logs.

Cluster-wide, you can use __Fluentd__ to aggregate logs.
__Fluentd__ is part of the Cloud Native Computing Foundation and, together with __Prometheus__, they make a nice combination for monitoring and logging.

Fluentd agents run on each node via a DaemonSet, they aggregate the logs, and feed them to an Elasticsearch instance prior to visualization in a Kibana dashboard

[More about Fluentd](https://kubernetes.io/docs/tasks/debug-application-cluster/logging-elasticsearch-kibana/)

### Monitoring Applications

As a distributed system, Kubernetes lacks monitoring and tracing tools which are cluster-aware. Other CNCF projects have started to handle various areas. As they are independent projects, you may find they have some overlap in capability:

- __Prometheus__
Focused on metrics and alerting. Provides a time-series database, queries and alerts to gather information and alerts for the entire cluster. With integration with Grafana, as well as simple graphs and console templates, you can easily visualize the cluster condition graphically

- __Fluentd__
A unified logging layer which can collect logs from over 500 plugins and deliver to a multitude of outputs. A single, enterprise-wide tool to filter, buffer, and route messages just about anywhere you may want.

- __OpenTracing__
While we just learned about logging and metrics, neither of the previously mentioned projects allow for a granular understanding of a transaction across a distributed architecture. This project seems to provide worthwhile instrumentation to propagate tracing among all services, code and packages, so the trace can be complete. Its goal is a “single, standard mechanism” for everything.

- __Jaeger__
A tracing system developed by Uber, focused on distributed context propagation, transaction monitoring, and root cause analysis, among other features. This has become a common tracing implementation of OpenTracing. You can see a Jaeger tracing example on the next page

![jaegar](https://raw.githubusercontent.com/zillani/img/master/k8s-resources/jaeger.jpg)

### System and Agent Logs

Where system and agent files are found depends on the existence of __systemd__. Those with systemd will log to __journalctl__, which can be viewed with __journalctl -a__.  Unless the __/var/log/journal__ directory exists, the journal is volatile. As Kubernetes can generate a lot of logs, it would be advisable to configure log rotation, should this directory be created.
Without __systemd__, the logs will be created under __/var/log/<agent>.log__, in which case it would also be advisable to configure log rotation.

#### Container components

- kube-scheduler
- kube-proxy​

#### Non-container components

- kubelet
- Docker

### Check Pod event

```bash
kubectl get pods secondapp
kubectl describe pod secondapp
```

### Check Container logs

```bash
kubectl logs secondapp webserver
kubectl logs secondapp busy
```

### Check DNS

```bash
kubectl exec -it secondapp -c busy -- sh
nslookup www.linux.com
cat /etc/resolv.conf
nc www.linux.com 25
wget http://linux.com
```

### Check Service and Endpoint

Check ports in service & yaml
Check ports in ep & yaml

```bash
kubectl get svc
kubectl get svc secondapp -o yaml
kubectl get ep
kubectl get ep secondapp -o yaml
```

### Check kube-proxy

Check kube-proxy logs, logs with 'I' for Info or 'E' for Error
Check iptables to verify if proxy is creating correct iprules.

```bash
ps -elf |grep kube-proxy
journalctl -a | grep proxy
cat  /var/log/kube-proxy.log
kubectl -n kube-system get pods
kubectl -n kube-system logs kube-proxy-fsdrx..
sudo iptables-save |grep secondapp
curl localhost:3200
```

## Conformance Testing

cncd.io formalized a test procedure for k8s cluster called conformance testing using sonobuoy.

Install gimme & go

```bash
mkdir ~/bin
curl -sL -o ~/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
chmod +x ~/bin/gimme
~/bin/gimme stable //downloads go
```

```bash
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
export PATH="/home/student/.gimme/versions/go1.13.linux.amd64/bin:${PATH}" //copied this from of gimme command
export GOPATH=$PATH
```

Clone sonobuoy

```bash
mkdir test
cd test
git clone https://github.com/heptio/sonobuoy
```

Navigate to sonobuoy,

```bash
cd ~/test/sonobuoy
```

Test using sonobuoy

```bash
go get -u -v github.com/heptio/sonobuoy
~/.gimme/versions/go1.13.linux.amd64/bin/bin/sonobuoy run //copy this from prev o/p
~/.gimme/versions/go1.13.linux.amd64/bin/bin/sonobuoy status
~/.gimme/versions/go1.10.3.linux.amd64/bin/bin/sonobuoy logs
cd ~/test/sonobuoy/pkg/client/results/testdata
```
