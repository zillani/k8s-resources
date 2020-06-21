# Troubleshooting (10%)

## Questions

### Troubleshoot application failure

<details><summary>show</summary>
<p>

Check Accessibility

```bash
curl http://web-service-ip:node-port
```

Check Service Status

```bash
kubectl describe svc web-service
```

compare the endpoints and selector on the POD definition

Check the POD

```bash
kubectl get po
kubectl describe po web
kubectl logs web
kubectl logs web -f
kubectl logs web -f --previous
```

</p>
</details>

### Troubleshoot control plane failure

<details><summary>show</summary>
<p>

Check Node Status

```bash
kubectl get nodes
kubectl get pods
```

Check Controlplane Pods

```bash
kubectl get pods -n kube-system
```

Check Controlplane Services

```bash
service kube-apiserver status
service kube-controller-manager status
service kube-scheduler status
service kubelet status
service kube-proxy status
```

Check Service Logs

```bash
kubectl logs kube-apiserver-master -n kube-system
sudo journalctl -u kube-apiserver

```

</p>
</details>

### Troubleshoot worker node failure

<details><summary>show</summary>
<p>

Check Node Status

```bash
kubectl get nodes
kubectl describe node <nodename>
top
df -h
service kubelet status
journalctl -u kubelet -f
openssl x509 -in /var/lib/kubelet/worker-1.crt -text

```

</p>
</details>

### Troubleshoot networking

<details><summary>show</summary>
<p>

- Make sure you’re connecting to the service’s cluster IP from within the cluster, not from the outside.

- Don’t bother pinging the service IP to figure out if the service is accessible (remember, the service’s cluster IP is a virtual IP and pinging it will never work).

- If you’ve defined a readiness probe, make sure it’s succeeding; otherwise the pod won’t be part of the service.

- To confirm that a pod is part of the service, examine the corresponding Endpoints object with kubectl get endpoints.

- If you’re trying to access the service through its FQDN or a part of it (for example, myservice.mynamespace.svc.cluster.local or myservice.mynamespace) and it doesn’t work, see if you can access it using its cluster IP instead of the FQDN.

- Check whether you’re connecting to the port exposed by the service and not the target port.

- Try connecting to the pod IP directly to confirm your pod is accepting connections on the correct port.

- If you can’t even access your app through the pod’s IP, make sure your app isn’t only binding to localhost.

</p>
</details>
