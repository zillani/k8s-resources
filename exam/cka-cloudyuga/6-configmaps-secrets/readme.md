# Configmaps and Secrets
## Table of Contents
1. [Configmaps](#Configmaps)
	1. [Configmap as volume](#Configmap-as-volume)
2. [Secrets](#secrets)
	1. [Secret as env variable](#secret-as-env-variable)
	2. [Secret as volumes](#secret-as-volumes)
	3. [Secret nginx](#secret-nginx)
	4. [Image pull secret]($image-pull-secret)

## Configmaps


```bash
kubectl apply -f 1-configmap.yaml
kubectl apply -f 2-rsvcconfigmap.yaml
kubectl apply -f 3-backend.yaml
```
#### Configmap as volume

```bash
kubectl apply -f 4-configvolume.yaml
kubectl exec config-volume ls /tmp/config
```

## Secrets

```bash
echo India|base64
W5kaWEK
echo Japan|base64
SmFwYW4K

```
Create secret using those encoded strings
```bash
kubectl apply -f 1-secret.yaml
```

#### Secrets as env variables

```bash
kubectl apply -f configs/2-secret-env.yaml
kubectl get po
kubectl exec secret-env printenv
```


#### Secrets as volumes 

```bash
 kubectl apply -f  configs/3-secret-vol.yaml
 kubectl exec -it nginx sh
```

#### Secret nginx

```bash
kubectl apply -f configs/4-secret-demo.yaml 
```

Access the application from 

```bash
http//<master-ip>:30080
https://<master-ip:30443
```

