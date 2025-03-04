# Application Lifecycle Management (8%)

## Questions

### Understand Deployments and how to perform  rolling updates and rollbacks

<details><summary>show</summary>
<p>

```bash
Note: Rolling Update is the default deployment strategy

kubectl rollout status deployment/myapp-deployment
kubectl rollout history deployment/myapp-deployment

You may wish to change the image of the container for the deployment to a new version such as image: nginx to image: nginx:1.7.1 and then run,

kubectl apply -f deployment.yaml

You can use imperative command to rollout update as well such as:

kubectl set image deplyoment/myapp-deployment nginx=nginx:1.7.1

But this will not update the original deployment YAML.

Check the replicasets during the rolling updates

kubectl get replicasets

In case of error in the deployment of your app run rollout to undo the update.

kubectl rollout undo deployment/myapp-deployment

If you wish to change the rolling update strategy to Recreate then edit the deployment

kubectl edit deployment myapp-deoloyment
```

</p>
</details>

### Know various ways to configure applications

<details><summary>show</summary>
<p>

```bash
cat pod.yaml
```

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sleep-pod
spec:
  selector:
    matchLabels: 
      app: sleep-app
  template:
    metadata:
      labels:
        app: sleep-app
    spec:
      containers:
        - name: nginx-container
          image: nginx
          command: ["sleep"]
          args: ["10"]
```

Define the POD with env key value pair.

```bash
cat pod-env-variable.yaml
```

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sleep-pod
spec:
 containers:
 - name: nginx-container
   image: nginx
   ports:
     - containerPort: 8080
   env:
     - name: app_type
       value: restapi
```

This is similar to the below Docker Run command

```bash
docker run -e app_type=restapi simple-color-container
```

You can use ConfigMap as the Key Value Pair to inject the env variable to the POD definition.

```bash
kubectl create configmap \
app-config --from-literal=app_color=blue \
--from-literal=app_type=prod

kubectl create configmap \
app-config --from-file=app_config.properties
```

```bash
cat configmap.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  App_color: blue
  App_mode: prod
```

```bash
kubectl get configmaps
kubectl describe configmaps

cat pod-env-variable-configmap.yaml
```

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sleep-pod
spec:
 containers:
 - name: nginx-container
   image: nginx
   ports:
     - containerPort: 8080
   envFrom:
     - configMapRef:
         name: app-config
```

Single Environment Variable from ConfigMap

```yaml
   env:
     - name: app_type
       valueFrom:
         configMapKeyRef:
           name: app-config
           key: app_color
```

Volume Environment Variable from ConfigMap

```yaml
volumes:
- name: app_config_vol
  configMap:
    name: app-config
```

In case, you want to pass on the env variable such as DB Host, User, Password to the web application then use Kubernetes Secrets.

```bash
kubectl create secret generic \
app-secret --from-literal=DB_host=mysql \
--from-literal=DB_user=root \
--from-literal=DB_passwd=mysql

kubectl create secret generic \
app-secret --from-file=app_secret.properties

```

Store the secret in encoded format

```bash
echo -n 'mysql' | base64 (repeat this for user and password)
cat secret.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  DB_host: mysql
  DB_user: root
  DB_password: passwd
```

```bash
kubectl get secrets
kubectl get secret app-secret -o yaml (this will show you the encoded value)
kubectl desc secrets

echo -n 'hashvalue' | base64 --decode (if you want to decode the secret value)
```

Create a Pod that will use the secret

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sleep-pod
spec:
 containers:
 - name: nginx-container
   image: nginx
   ports:
     - containerPort: 8080
   envFrom:
   - secretRef:
       name: app-secret
```

</p>
</details>

### Know how to scale applications

<details><summary>show</summary>
<p>

```bash
kubectl scale deployments/kubernetes-bootcamp --replicas=4
kubectl edit (replicas object)
--replicas in POD
```

</p>
</details>

### Understand the primitives necessary to create a self-healing application

<details><summary>show</summary>
<p>

```bash
Kubernetes supports self-healing applications through ReplicaSets and Replication Controllers. The replication controller helps in ensuring that a POD is re-created automatically when the application within the POD crashes. It helps in ensuring enough replicas of the application are running at all times.

Kubernetes provides additional support to check the health of applications running within PODs and take necessary actions through Liveness and Readiness Probes.
```

</p>
</details>
