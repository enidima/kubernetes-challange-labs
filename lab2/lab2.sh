#!/bin/bash

kubectl config set clusters.kubernetes.server https://controlplane:6443

# crictl logs $(crictl ps --name kube-apiserver -a -o json | jq -r .containers[0].id)
# > E0409 15:39:00.373714       1 run.go:120] "command failed" err="open /etc/kubernetes/pki/ca-authority.crt: no such file or directory"

sed -i 's:client-ca-file=/etc/kubernetes/pki/ca-authority.crt:client-ca-file=/etc/kubernetes/pki/ca.crt:' /etc/kubernetes/manifests/kube-apiserver.yaml 

kubectl -n kube-system set image deploy coredns coredns="k8s.gcr.io/coredns/coredns:v1.8.6"

sleep 10

kubectl uncordon node01

scp -r /media/* root@node01:/web

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /web
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  volumeName: data-pv
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: gop-file-server
  name: gop-file-server
spec:
  containers:
  - image: kodekloud/fileserver
    name: gop-file-server
    resources: {}
    volumeMounts:
    - name: data-store
      mountPath: /web
  volumes:
  - name: data-store
    persistentVolumeClaim:
      claimName: data-pvc
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: gop-file-server
  name: gop-fs-service
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
    nodePort: 31200
  selector:
    run: gop-file-server
  type: NodePort
status:
  loadBalancer: {}
EOF