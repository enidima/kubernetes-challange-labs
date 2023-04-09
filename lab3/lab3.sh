#!/bin/bash

kubectl apply -f - <<EOF
# Create a new namespace: name = 'vote'
apiVersion: v1
kind: Namespace
metadata:
  name: vote

---

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: result-deployment
  name: result-deployment
  namespace: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: result-deployment
  template:
    metadata:
      labels:
        app: result-deployment
    spec:
      containers:
      - image: kodekloud/examplevotingapp_result:before
        name: examplevotingapp-result-n4rh5

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: result-deployment
  name: result-service
  namespace: vote
spec:
  ports:
  - port: 5001
    protocol: TCP
    targetPort: 80
    nodePort: 31001
  selector:
    app: result-deployment
  type: NodePort

---

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: db-deployment
  name: db-deployment
  namespace: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db-deployment
  template:
    metadata:
      labels:
        app: db-deployment
    spec:
      containers:
      - image: postgres:9.4
        name: postgres
        env:
        - name: POSTGRES_HOST_AUTH_METHOD
          value: trust
        volumeMounts:
        - name: db-data
          mountPath: /var/lib/postgresql/data
      volumes:
      - emptyDir: {}
        name: db-data

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: db-deployment
  name: db
  namespace: vote
spec:
  ports:
  - port: 5432
    protocol: TCP
    targetPort: 5432
  selector:
    app: db-deployment

---

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: worker
  name: worker
  namespace: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
      - image: kodekloud/examplevotingapp_worker
        name: examplevotingapp-worker-5jdp6

---

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis-deployment
  name: redis-deployment
  namespace: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-deployment
  template:
    metadata:
      labels:
        app: redis-deployment
    spec:
      containers:
      - image: redis:alpine
        name: redis
        volumeMounts:
        - mountPath: /data
          name: redis-data
      volumes:
      - emptyDir: {}
        name: redis-data

---

apiVersion: v1
kind: Service
metadata:
  labels:
    app: redis-deployment
  name: redis
  namespace: vote
spec:
  ports:
  - port: 6379
    protocol: TCP
    targetPort: 6379
  selector:
    app: redis-deployment

---

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: vote-deployment
  name: vote-deployment
  namespace: vote
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vote-deployment
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: vote-deployment
    spec:
      containers:
      - image: kodekloud/examplevotingapp_vote:before
        name: examplevotingapp-vote-j6wwv

---

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: vote-deployment
  name: vote-service
  namespace: vote
spec:
  ports:
  - port: 5000
    protocol: TCP
    targetPort: 80
    nodePort: 31000
  selector:
    app: vote-deployment
  type: NodePort

EOF