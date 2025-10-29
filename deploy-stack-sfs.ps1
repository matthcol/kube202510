$KUBECTL_NAMESPACE = "moviens2"
kubectl create namespace ${KUBECTL_NAMESPACE}
kubectl config set-context --current --namespace ${KUBECTL_NAMESPACE}

kubectl create cm database-env --from-env-file ./database/.db-env
kubectl create cm ddl-init --from-file ./database/sql/01-tables.sql
kubectl create secret generic db-secret '--from-literal=DB_PASSWORD=nottoocomplicatedpassword' 


kubectl apply -f database/db.statefulset.yml
