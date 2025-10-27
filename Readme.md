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
kubectl get deploy -l app=nginx-dy -o yaml 
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

On peut labeliser via le fichier Yaml ou en CLI:
kubectl label pod/nginx-solo topic=vin
kubectl label po,rs,deploy -l app=hello-minikube1 topic=world
kubectl label po,rs,deploy -l app=hello-minikube1 topic=vin dept=47         # plusieurs labels
kubectl label po,rs,deploy -l app=hello-minikube1 --overwrite topic=france  # change value of a label
 kubectl label po,rs,deploy -l app=hello-minikube1 topic-                   # delete label

## Update

Rolling update (CLI ou modify Yaml config):
```
kubectl set image deploy nginx-dy nginx-dy=nginx:1.28
kubectl get po -l app=nginx-dy -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
kubectl rollout status deploy nginx-dy 
```

## PostgreSQL database
Déploiement avec fichier Yaml:
```
kubectl -f db.deployment.yml
kubectl get po,rs,deploy -l app=dbmovie
kubectl exec -it dbmovie-56b8ddb895-xr9b2 -- psql -U postgres -d postgres
kubectl exec -it dbmovie-56b8ddb895-xr9b2 -- psql -U movie -d dbmovie
    \l
    \d
    \du
```