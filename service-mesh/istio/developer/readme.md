# learn-istio
Guide for learning istio

### installation
- requres 4gb of ram and 2vCPUs
- swapoff & untaint master node if single node cluster
- check kubelet logs, calico status & node status
[install istio](https://istio.io/docs/setup/getting-started/#download)
delete kiali service & expose kiali as nodeport
- kiali default creds is admin/admin

### istio operator crashloopbackoff
[calico-problem](https://github.com/kubernetes-sigs/metrics-server/issues/375)

### installing canal
[calico+flannel is canal](https://docs.projectcalico.org/getting-started/kubernetes/flannel/flannel)

### install istio for calico

### Overview
- install k8s & calico cni
- [install istio for calico](https://docs.projectcalico.org/getting-started/kubernetes/hardway/istio-integration)
- or you may only need `istioctl` which is easy

```bash
istioctl manifest apply --set profile=demo
```
- all issues were related to network, so check /etc/hosts & untaint master nodes (for local vms) & increase disk space to master node. Remove the fault node(drain) & put it back (uncordon later) but clean it (kubeadm reset)
- [also, may need to clean up cni](https://github.com/kubernetes/kubernetes/issues/39557)
- for me the main issue was fixing /etc/hosts with my ip address

```bash
127.0.0.1 localhost
192.168.110.129 ubuntu1 # I had 127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

### Expose services
All of them are clusterIP exposed, so expose to nodePort and access it via nodeport example,
```bash
 k expose deployment grafana -n istio-system --type=NodePort --port=3000 --dry-run -oyaml > grafana.yml
```
then edit this yaml to change the service name.
after than you can access on your host using the vm <ipaddress:nodeport>
in my case, `http://192.168.110.129:32524` for grafana and `http://192.168.110.129:30028/kiali` for kiali, 
for kiali, the creds are admin/admin, it will take a min or so to load, be patient.

## cilium way

- install cilium 
- [cilium-istio](https://docs.cilium.io/en/stable/gettingstarted/istio/)
- mem for istio 4096



