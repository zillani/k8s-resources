# Storage (7%)

## Questions

### Understand persistent volumes and know how to create them

<details><summary>show</summary>
<p>

```bash
cat persist-pod-volume.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: persistent-pod
spec:
  containers:
  - name: alpine
    image: alpine
    command: ["/bin/sh","-c"]
    args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
    volumeMounts:
    - mountPath: /opt
      name: data-volume
  volumes:
  - name: data-volume
    hostPath:
      path: /data
      type: Directory
```

```bash
cat persistent-volume.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
     - ReadWriteOnce
  capacity:
    storage: 1Gi
  hostPath:
    path: /tmp/data
```

```bash
kubectl get persistentvolumes
```

</p>
</details>

### Understand access modes for volumes

<details><summary>show</summary>
<p>

```bash
ReadWriteOnce – the volume can be mounted as read-write by a single node
ReadOnlyMany – the volume can be mounted read-only by many nodes
ReadWriteMany – the volume can be mounted as read-write by many nodes

```

</p>
</details>

### Understand persistent volume claims primitive

<details><summary>show</summary>
<p>

```bash
cat pvc.yaml
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
  
  resources:
    requests:
      storage: 500Mi
```

Persistent Volume Reclaim Policies:

Retain: No other claims can claim this volume
Delete: Delete the volume
Recycle: Scrap the data and make the volume available again

```bash
kubectl get persistentvolumeclaim
kubectl delete persistentvolumeclaim myclaim

cat pvc-claim-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  containers:
  - name: event-simulator
    image: kodecloud/event-simulator
    env:
    - name: Log_Handler
      value: file
    volumeMounts:
    - mountPath: /log
      name: log-volume
  volumes:
  - name: log-vol
    persistentVolumeClaim:
      claimName: claim-log-1

```

</p>
</details>

### Understand Kubernetes storage objects

<details><summary>show</summary>
<p>

Kubernetes supports several types of Volumes:

- awsElasticBlockStore
- azureDisk
- azureFile
- cephfs
- cinder
- configMap
- csi
- downwardAPI
- emptyDir
- fc (fibre channel)
- flexVolume
- flocker
- gcePersistentDisk
- gitRepo (deprecated)
- glusterfs
- hostPath
- iscsi
- local
- nfs
- persistentVolumeClaim
- projected
- portworxVolume
- quobyte
- rbd
- scaleIO
- secret
- storageos
- vsphereVolume

</p>
</details>

### Know how to configure applications with persistent storage

<details><summary>show</summary>
<p>

Create a persistent volume claim
Use persistent volume claim in pod

</p>
</details>
