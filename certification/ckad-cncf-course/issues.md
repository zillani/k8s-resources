# Issues
 1. [Upgrade issue](#Upgrade-issue)
 2. [x509 certificate error](#x509-certificate-error)
 3. [resolv.cnf gets overridden](#resolv.cnf-gets-overridden)
 4. [ipaddress of master got updated](#ipaddress-of-master-got-updated)
 5. [container stays in creating state](#container-stays-in-creating-state)
 6. [unable to access pod via podip](#unable-to-access-pod-via-podip)
 7. [renaming node](#renaming-node)

## Upgrade issue

FATAL: this version of kubeadm only supports deploying clusters 
with the control plane version >= 1.16.0. Current version: v1.14.1

```bash
 You need to upgrade from 1.14 to 1.15 then 1.16 to 1.17
```

## x509 certificate error

```
Error:
x509: certificate signed by unknown authority 
(possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")
```
```bash
rm -rf ~/.kube/config
cat /etc/kubernetes/admin.conf > ~/.kube/config
```

## resolv.cnf gets overridden

![what overrides etc/resolv.conf](https://unix.stackexchange.com/questions/174349/what-overwrites-etc-resolv-conf-on-every-boot)
dont' forget to turnoff swap

## ipaddress of master got updated

![check this](https://github.com/kubernetes/kubeadm/issues/338#issuecomment-605435843)

## container stays in creating state

this issue occurred with calico v3.11, so use calico v3.9 instead.
```bash
FailedCreatePodSandBox 16h kubelet, controller-1 Failed create pod sandbox: rpc error: code = Unknown desc = [failed to set up sandbox container "bf09a329e420195005783041fd4be31e2a3ab3a1396e9a5f40ca3b69d5dc6267" network for pod "ceph-pools-audit-1570654500-8g9kd": NetworkPlugin cni failed to set up pod "ceph-pools-audit-1570654500-8g9kd_kube-system" network: Multus: Err adding pod to network "chain": Multus: error in invoke Conflist add - "chain": error in getting result from AddNetworkList: error getting ClusterInformation: Get https://[10.96.0.1]:443/apis/crd.projectcalico.org/v1/clusterinformations
```

## unable to access pod via podip

ipaddress of nodes might have changes via dhcp

## renaming node
[node rename](https://stackoverflow.com/questions/46006716/how-to-change-name-of-a-kubernetes-node)
