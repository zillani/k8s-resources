First install the helloworld.yaml & then install the helloworld-nodeport.yaml

#### Nodeport

Please observe the label selection is the imp thing, which will map our application to the node-port service deployment. 
After exposing the app as node port, you can access the application from node-ip on node-port, 
to check the node port, use,
```
kubectl get svc
```
example,
```
curl localhost:32738
```


