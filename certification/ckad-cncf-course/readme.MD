# k8s-resources 
to check which version (kubeadm/kubectl/kubelet) to install: apt-cache policy kubeadm


## ERRORS


### error at kubeadm/kubectl/kubelet
make sure the versions are properly set

### error at kubeadm
https://linuxacademy.com/community/show/28209-error-kubeletversion-the-kubelet-version-is-higher-than/

### error installing calico
https://docs.projectcalico.org/v3.9/getting-started/kubernetes/installation/calico

### unable to add worker nodes to master (Azure)
make sure nodes are on same vnet and subnet and security group has ports enabled esp 6443

### unable to add worker nodes to master (AWS)
make sure nodes are on same vpc and subnet and security group has ports enabled esp 6443
