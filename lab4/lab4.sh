#!/bin/bash

for ((i=1; i<=6; i++)); do
    # ensure first the path on worker node exists
    ssh root@node01 -- mkdir -p "/redis0$i" 

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: redis0$i
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /redis0$i
EOF
done

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: redis-cluster-service
  name: redis-cluster-service
spec:
  ports:
  - name: "client"
    port: 6379
    protocol: TCP
    targetPort: 6379
  - name: "gossip"
    port: 16379
    protocol: TCP
    targetPort: 16379
  selector:
    app: redis-cluster
  type: ClusterIP

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  creationTimestamp: null
  labels:
    app: redis-cluster
  name: redis-cluster
spec:
  replicas: 6
  serviceName: redis-cluster-service
  selector:
    matchLabels:
      app: redis-cluster
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: redis-cluster
    spec:
      volumes:
      - name: conf
        configMap:
          name: redis-cluster-configmap
          defaultMode: 0755
      containers:
      - image: redis:5.0.1-alpine
        name: redis
        command:  ["/conf/update-node.sh", "redis-server", "/conf/redis.conf"]
        env:
        - name: POD_IP
          valueFrom:
            fieldRef: 
              fieldPath: status.podIP
        ports:
        - containerPort: 6379
          name: client
        - containerPort: 16379
          name: gossip
        volumeMounts:
        - mountPath: /conf
          name: conf
          readOnly: false
        - mountPath: /data
          name: data
          readOnly: false
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi

EOF

# wait for 6 pods to be running 
sleep 150

kubectl exec -it redis-cluster-0 -- redis-cli --cluster create --cluster-replicas 1 $(kubectl get pods -l app=redis-cluster -o jsonpath='{range.items[*]}{.status.podIP}:6379 {end}')