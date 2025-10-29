$KUBECTL_NAMESPACE = "moviens"
kubectl create namespace ${KUBECTL_NAMESPACE}
kubectl config set-context --current --namespace ${KUBECTL_NAMESPACE}

kubectl create cm database-env --from-env-file ./database/.db-env

kubectl create cm ddl-init --from-file ./database/sql/01-tables.sql
# kubectl create cm ddl-init --from-file=./database/sql/01-tables.sql --dry-run=client -o yaml > ./database/ddl-init.configmap.yml
# kubectl apply -f ./database/ddl-init.configmap.yml

kubectl create secret generic db-secret '--from-literal=DB_PASSWORD=nottoocomplicatedpassword' 

kubectl apply -f database/db.pvc.yml
kubectl apply -f database/db.deployment.yml
kubectl rollout status deploy dbmovie
kubectl apply -f database/db.service.yml

kubectl apply -f api/api.deployment.yml
kubectl rollout status deploy movieapi
kubectl apply -f api/api.service.yml
