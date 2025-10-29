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

kubectl get storageclass

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

**8 types natifs** :
1. `Opaque`
2. `kubernetes.io/service-account-token`
3. `kubernetes.io/dockercfg`
4. `kubernetes.io/dockerconfigjson`
5. `kubernetes.io/basic-auth`
6. `kubernetes.io/ssh-auth`
7. `kubernetes.io/tls`
8. `bootstrap.kubernetes.io/token`

**+ Types personnalisés illimités**
Exemple: HashiCorp Vault

Exemple avec 1 secret generic de type opaque:
```
kubectl create secret generic db-secret '--from-literal=DB_PASSWORD=qqMjdkq#!@%34' 
kubectl get secret/db-secret -o json

kubectl get po -l app=dbmovie -o wide    # => IP
$POD=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- psql -U $DB_USER -d $DB_NAME -h 10.244.0.67
```

## Services
Services gérés par k8s:
- ClusterIp : communication interne entre conteneurs (défaut)
- NodePort : accès direct sur le noeud depuis l'extérieur (standalone)
- LoadBalancer : accès exterieur avec un replicaset (n > 1)
- ExternalName: accès par DNS

Autres types de service:
- Ingress


kubectl expose pod hello-minikube1-68d8f56889-5t9xg --type=NodePort --port 8080 --name hello-service
kubectl expose pod hello-minikube1-68d8f56889-5t9xg --type=NodePort --port 8081 --target-port 8080 --name hello-service

minikube ssh 
    curl 10.98.2.186:8081

kubectl port-forward service/hello-service 8081:8081


kubectl scale deploy hello-minikube1 --replicas=3
kubectl get po,svc -l app=hello-minikube1 -o wide 

minikube addons enable ingress

## Namespaces

Tous les namespaces: -A
kubectl get po -A

Préciser un namespace: -n
kubectl get po -n kube-system

kubectl create namespace moviens
kubectl get ns  

### Methode1 explicite
Utiliser -n dans chaque commande ou clé namespace dans le yaml:
kubectl create configmap database-env -n moviens --from-literal DB_NAME=dbmovie --from-literal DB_USER=movie
kubectl get cm -n moviens 

### Methode 2: env variable
```
$env:KUBECTL_NAMESPACE = "moviens"
function kns {
    kubectl -n $env:KUBECTL_NAMESPACE @args
}
```
### Methode 3: config
```
kubectl config set-context --current --namespace moviens
kubectl config get-contexts 

# use new default ns
kubectl get cm   # automatically in the good namespace
```

## Image custom
cd .\api\api-v1.0\
docker build -t movieapi:1.0 .

## Atelier stack API-DB
Exemple de DB_URL pour l'api movieapi: postgresql+psycopg2://scott:tiger@localhost:5432/mydatabase

(Re)create all from scratch:
```
kubectl delete ns moviens
./deploy-stack.ps1
```

Test with scripts:
```
./import-data.ps1
./test-stack.ps1
```

### Mise à jour API

cd api/api-v2.0
docker build -t movieapi:2.0 .   # use file Dockerfile

Mise à jour en CLI
kubectl set image deploy/movieapi movieapi=movieapi:2.0
kubectl rollout status deploy/movieapi
kubectl rollout history deploy/movieapi

kubectl get po -l app=movieapi -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
kubectl describe pod movieapi-85dd5bcc46-hzxd9

Annuler la mise à jour:
kubectl rollout undo deploy/movieapi
kubectl rollout undo deploy/movieapi --to-revision=2

Tester la disponibilité de l'API
```
kubectl run test-curl -it --rm --restart=Never --image=curlimages/curl -- sh

# one query
curl -s -w "[%{remote_ip}] %{http_code} %{time_total}s\n " -G http://movieapi:8090/movies/

# 1000 queries by 10 workers
seq 1000 | xargs -n1 -P10 -I{} curl -s -w "[%{remote_ip}] %{http_code} %{time_total}s\n " -G http://movieapi:8090/movies/ -o /dev/null
```

Canary deployment

```
 kubectl set image deploy/movieapi movieapi=movieapi:2.0               
 kubectl rollout pause deploy/movieapi
 
 # test canary pod:
 curl -s -w "[%{remote_ip}] %{http_code} %{time_total}s\n " -G http://10.244.0.145:8080/persons/ -o 
/dev/null

 kubectl rollout resume deploy/movieapi  # ou undo
```

NB: autre possibilité: faire un deploiement canary avec 1 replica et la nouvelle version

Changement de config
1 - Editer configmap ou secret
echo newpassword | base64
kubectl edit secret db-secret
2 - Changement en base de données
3 - Rollout restart
kubectl rollout restart deploy movieapi

## Tolérance aux pannes

### Restart auto
Un déploiement (avec replica set): reconstruction automatique des pods:
```
kubectl delete po movieapi-5dbd79b54b-cg6pl # => new pod créé
kubectl delete po dbmovie-d9c4d5447-nzbtr   # idem
```

### Init Container
Test dependencies or prepare something before starting container

### Probes
Customize liveness and readiness of a container

Probe types:
- httpGet (API, frontend) => OK si status 2xx ou 3xx
- tcpSocket (DB) => OK si réponse
- exec (any command) => OK status 0

## StatefulSet
- Pod à état
- stabilité des noms
- service Headless:
    * nom service
    * nom pour chaque replica

Install:
```
kubectl apply -f .\database\db.statefulset.yml 
kubectl get all
kubectl get endpoints movieservice 
```

Test each pod:
```
kubectl run -it --rm --restart=Never test-pg --image=postgres:18 -- bash
    psql -U moviemanager -d moviedb -h moviedb-0.movieservice.moviens2.svc.cluster.local
    psql -U moviemanager -d moviedb -h moviedb-1.movieservice.moviens2.svc.cluster.local
```

Chaque pod à un nom sur le modèle suivant:
<pod-name>.<headless-service>.<namespace>.svc.cluster.local

## Jobs
Tâches planifiées
- one shot: job
- récurrent: cronjob

Exemples :
- backup
- purge ou nettoyage

## Gestionnaire de configuration
- Helm Charts
```
cd stack-helm
helm install movies . -n moviens3 --create-namespace
helm list -n moviens3   
helm uninstall movies -n moviens3  
```