##OOM test

```
docker run --rm  -e JVM_OPTS="-XX:MaxHeapSize=20m" oom-generator

kubectl apply -f pod-oom.yaml
```
