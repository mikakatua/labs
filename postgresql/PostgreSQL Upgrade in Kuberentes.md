# Upgrade a PostgreSQL database in Kubernetes

The current PostgreSQL image is `bitnami/postgresql:11.14.0-debian-10-r22` and we want to upgrade it to the latest version

1. Stop (scale to 0 replicas) any application using the database
```
kubectl scale sts sonar-sonarqube --replicas=0
```
2. Take a full backup of the database
```
kubectl exec sonar-postgresql-0 -- \
sh -c 'PGPASSWORD=$POSTGRES_POSTGRES_PASSWORD pg_dumpall -U postgres' > dump.sql
```
3. Edit the database deployment and add the command `sleep infinity` to replace the image entry point
```
kubectl edit sts sonar-postgresql
```
```
spec:
  template:
    spec:
      containers:
        name: sonar-postgresql
        command:
        - sleep
        - infinity
```
**Note**: Optionally remove the livenessProve to avoid Pod restarts

4. Delete the PostgreSQL data directory
```
kubectl exec sonar-postgresql-0 -- sh -c 'rm -rf $PGDATA/*'
```
5. Edit the database deployment, remove the command and set the new image
```
kubectl edit sts sonar-postgresql
```
```
spec:
  template:
    spec:
      containers:
        name: sonar-postgresql
        image: docker.io/bitnami/postgresql:14.2.0-debian-10-r88
```
6. Delete the current Pod to force the creation of a new one that uses the new image
```
kubectl delete pod sonar-postgresql-0
```
7. Restore the backup
```
cat dump.sql | kubectl exec -i sonar-postgresql-0 -- \
sh -c 'PGPASSWORD=$POSTGRES_POSTGRES_PASSWORD psql -U postgres'
```
**Note**: If the backup was taken from another server, edit the dumpfile and replace the passwords to macth the destination

8. Start again the application
```
kubectl scale sts sonar-sonarqube --replicas=1
```