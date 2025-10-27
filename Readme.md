# Kubernetes

## Minikube
https://minikube.sigs.k8s.io/docs/start

### Minikube management
```
minikube start|stop|status

# dind transparent:
minikube docker-env  

minikube dashboard
```

## Kubectl
CLI management of kubernetes

```
kubectl version
```

### Pods
1 pod = 1 container

Pods can be deployed within a deployment

```
kubectl create deployment hello-minikube1 --image=kicbase/echo-server:1.0
kubectl create deployment nginx --image=nginx:1.29

kubectl delete deploy nginx
```

Without deployment layer:
```
kubectl run nginx-solo --image=nginx:1.29
```

Liste et status des pods
```
kubectl get po
kubectl get pod
kubectl get pods

kubectl get pod/nginx-solo
kubectl get pod/nginx-solo -o wide
kubectl get pod/nginx-solo -o json
kubectl get pod/nginx-solo -o jsonpath="{.spec..image}"
kubectl get po -l app=nginx-dy -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

Superviser et interagir avec un pod:
```
kubectl logs nginx-solo
kubectl logs nginx-6f5fc479d9-jn4fb
kubectl exec -it nginx-solo -- bash
```

Appliquer une configuration Yaml:
```
kubectl apply -f nginx.deployment.yml
```
minikube ssh 
    curl 10.244.0.19

minikube ssh "curl 10.244.0.19"

kubectl run test-curl -it --rm --image=curlimages/curl -- sh
    curl 10.244.0.19
TODO: kubectl run test-curl -it --rm --image=curlimages/curl -- curl 10.244.0.19

## Labels
kubectl get po --show-labels
kubectl get po,deploy,rs -l app=nginx-dy
