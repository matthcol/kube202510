$API_PORT=8090
$DB_NAME="moviedb"
$DB_USER="moviemanager"
$POD_DB_BASENAME="dbmovie"

$POD_DB=$(kubectl get po -l app=${POD_DB_BASENAME} -o jsonpath='{.items[0].metadata.name}')

Write-Output "`n`n******* K8S components *******"
kubectl get pvc,cm,secret,po,rs,deploy,svc

Write-Output "`n`n******* Query the database *******"

kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) as nb_person FROM person"
kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT * FROM person LIMIT 10"
kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) as nb_movie FROM movie"
kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT title, year, duration FROM movie LIMIT 10"

Write-Output "`n`n******* Query the api  *******"
curl -G "http://localhost:${API_PORT}/movies/" | 
    ConvertFrom-Json | 
    ConvertTo-Json -Depth 10 | 
     Out-String |
    ForEach-Object { $_ -split "`n" } |
    Select-Object -Last 20

Write-Output "`n`n******* Add movie with API *******"
curl -X 'POST' `
  "http://localhost:${API_PORT}/movies/" `
  -H 'accept: application/json' `
  -H 'Content-Type: application/json' `
  -d '{
  "title": "The Long Walk",
  "year": 2025,
  "duration": 120
}'

Write-Output "`n`n ****** Read all movies from API ******"
curl -G "http://localhost:${API_PORT}/movies/" | 
    ConvertFrom-Json | 
    ConvertTo-Json -Depth 10 | 
     Out-String |
    ForEach-Object { $_ -split "`n" } |
    Select-Object -Last 20

Write-Output "`n`n ****** Check DB after using API ******"
kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) as nb_person FROM person"
kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) as nb_movie FROM movie"
kubectl exec -it $POD_DB -- psql -U $DB_USER -d $DB_NAME -c "SELECT title, year, duration FROM movie where year = 2025"
