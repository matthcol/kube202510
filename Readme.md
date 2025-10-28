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

Manage context (cluster): can be stored in ~/.kube/config
```
kubectl config current-context      
kubectl config get-contexts
kubectl config use-context <name_of_context>
kubectl config view
```

## Pods
1 pod = 1 container

### Pods in a deployment
Pods can be deployed within a deployment: easier to update, have replicas

```
kubectl create deployment hello-minikube1 --image=kicbase/echo-server:1.0
kubectl create deployment nginx --image=nginx:1.29

kubectl delete deploy nginx
```

### Pods without deployment
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

### Test Pod
Execute a command within cluster (on the master):
```
minikube ssh 
    curl 10.244.0.19

minikube ssh "curl 10.244.0.19"
```

Or use another pod:
```
kubectl run test-curl -it --rm --image=curlimages/curl -- sh
    curl 10.244.0.19
```

TODO: kubectl run test-curl -it --rm --image=curlimages/curl -- curl 10.244.0.19

## Labels
Show labels:
```
kubectl get po --show-labels
```

Select by label:
```
kubectl get po,deploy,rs -l app=nginx-dy
```

On peut labeliser via le fichier Yaml ou en CLI:
```
kubectl label pod/nginx-solo topic=vin
kubectl label po,rs,deploy -l app=hello-minikube1 topic=world
kubectl label po,rs,deploy -l app=hello-minikube1 topic=vin dept=47         # plusieurs labels
kubectl label po,rs,deploy -l app=hello-minikube1 --overwrite topic=france  # change value of a label
kubectl label po,rs,deploy -l app=hello-minikube1 topic-                    # delete label
```

## Manage updates

Rolling update (CLI ou modify Yaml config):
```
kubectl set image deploy nginx-dy nginx-dy=nginx:1.28
kubectl get po -l app=nginx-dy -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
kubectl rollout status deploy nginx-dy 
```

## PostgreSQL database example
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

NB: pour interragir avec un pod en mode semi-automatique (adapter la syntaxe au CLI):
```
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}') 
kubectl logs $POD
kubectl exec -it $POD -- psql -U movie -d dbmovie
```

### Config Map
#### Config Map with variables
kubectl create configmap database-env --from-literal DB_NAME=dbmovie --from-literal DB_USER=movie
kubectl get cm database-env -o jsonpath='{.data}'
kubectl delete cm database-env

kubectl create cm database-env --from-env-file .db-env
kubectl get cm database-env -o jsonpath='{.data}'

NB: forcer à relire le configmap
```
kubectl rollout restart deploy dbmovie
```

#### Config Map with files
```
kubectl create cm ddl-init --from-file ./sql/01-tables.sql
kubectl create cm ddl-init --from-file ./sql                # tout le contenu du dossier
kubectl get cm ddl-init -o jsonpath='{.data}'
```

Apres intégration du config map dans le yaml du deploiement:

```
kubectl apply -f .\db.deployment.yml 
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD
kubectl exec -it $POD -- psql -U moviemanager -d moviedb
    \d   # bien voir toutes les tables
```

### Data Persistence
```
. .\.db-env.ps1
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl cp .\sql\02-data-persons.sql ${POD}:/tmp
kubectl exec -it $POD -- ls -l /tmp
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -f /tmp/02-data-persons.sql
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM person"
```

kubectl delete pod $POD   # destroyed and recreated automatically
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM person"

Diiferent types de PVC

| Mode | Abréviation | Description |
|------|-------------|-------------|
| ReadWriteOnce | RWO | Lecture-écriture, un nœud |
| ReadOnlyMany | ROX | Lecture seule, plusieurs nœuds |
| ReadWriteMany | RWX | Lecture-écriture, plusieurs nœuds |
| ReadWriteOncePod | RWOP | Lecture-écriture, un seul pod |

kubectl apply -f db.pvc.yml
kubectl apply -f db.deployment.yml
kubectl get po,pvc -l app=dbmovie       # POD has been replaced
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM person"
kubectl describe pod $POD

kubectl cp .\sql\02-data-persons.sql ${POD}:/tmp
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -f /tmp/02-data-persons.sql
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM person"

kubectl delete pod $POD   # destroyed and recreated automatically
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM person"

### Secrets
kubectl create secret generic db-secret '--from-literal=DB_PASSWORD=qqMjdkq#!@%34' 
kubectl get secret/db-secret -o json

kubectl get po -l app=dbmovie -o wide    # => IP
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -h 10.244.0.67