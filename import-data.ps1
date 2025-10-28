$DB_NAME="moviedb"
$DB_USER="moviemanager"
$POD_DB=$(kubectl get po -l app=dbmovie -o jsonpath='{.items[0].metadata.name}')

foreach ($file in Get-ChildItem -Path ./database/sql -Filter "*.sql" | Where-Object { $_.Name -match '^0[2-6].*\.sql$' }) {
    Write-Output "Copy file in pod ${POD_DB}: ./database/sql/$($file.Name)"
    kubectl cp ./database/sql/$($file.Name) ${POD_DB}:/tmp
    Write-Output "Execute SQL in pod ${POD_DB}: /tmp/$($file.Name)"
    kubectl exec -it ${POD_DB} -- psql -U $DB_USER -d $DB_NAME -f /tmp/$($file.Name)
}