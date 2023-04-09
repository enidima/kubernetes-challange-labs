#!/bin/sh

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jekyll-site
  namespace: development
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  volumeName: jekyll-site
  storageClassName: local-storage
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: jekyll
  name: jekyll
  namespace: development
spec:
  containers:
  - image: kodekloud/jekyll-serve
    name: jekyll
    volumeMounts:
    - mountPath: /site
      name: site
  initContainers:
  - name: copy-jekyll-site
    image: kodekloud/jekyll
    command: [ "jekyll", "new", "/site" ]
    volumeMounts:
    - mountPath: /site
      name: site
  volumes:
  - name: site
    persistentVolumeClaim:
      claimName: jekyll-site
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: jekyll
  name: jekyll
  namespace: development
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 4000
    nodePort: 30097
  selector:
    run: jekyll
  type: NodePort
status:
  loadBalancer: {}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: developer-role
  namespace: development
rules:
- apiGroups:
  - ""
  resources:
  - services
  - persistentvolumeclaims
  - pods
  verbs:
  - '*'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  name: developer-rolebinding
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer-role
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: martin

EOF

kubectl config set-context developer --user=martin --cluster=kubernetes --namespace=developer
kubectl --context developer config set-credentials martin --client-certificate=/root/martin.crt --client-key=/root/martin.key
kubectl config use-context developer