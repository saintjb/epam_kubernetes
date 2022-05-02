# Homework

## 3.1 We published minio "outside" using nodePort. Do the same but using ingress.

Create namespace and set namespace task3 as default

Create ClusterIP service
```bash
kubectl expose deployment minio --type=ClusterIP --dry-run=client -o yaml | grep -v creationTimestamp > minio-balancer.yml
kubectl apply -f minio-balancer.yml
```

Create Ingress for incoming traffic
```bash
cat <<-EOF | tee minio-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minio-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
             name: minio
             port: 
                number: 9001
EOF
```
```
kubectl apply -f minio-ingress.yml
```

Check access via minikube ip
```bash
curl -D - -s -o /dev/null $(minikube ip)
HTTP/1.1 200 OK
Date: Mon, 02 May 2022 20:43:41 GMT
Content-Type: text/html
Content-Length: 1356
Connection: keep-alive
Accept-Ranges: bytes
Last-Modified: Mon, 02 May 2022 20:43:41 GMT
Vary: Accept-Encoding
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-Xss-Protection: 1; mode=block
```

## 3.2 Publish minio via ingress so that minio by ip_minikube and nginx returning hostname (previous job) by path ip_minikube/web are available at the same time.

Create services 
```bash
kubectl create deployment nginx-v1 --image=nginx --replicas=1 --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
kubectl expose deployment nginx-v1 --port=80 --type=ClusterIP
```
Create ingress tempate for `/`
```
kubectl create ingress minio-ingress --rule="/*=minio:9001" --dry-run=client -o yaml | grep -v creationTimestamp > minio-ingress.yml
```
cat <<-EOF | tee minio-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minio-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /\$1
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: minio
            port:
              number: 9001
        path: /(.*)
        pathType: Prefix
status:
  loadBalancer: {}
EOF
```

Create template for `/web`
```bash
cat <<-EOF | tee nginx-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: nginx-v1
            port:
              number: 80
        path: /(web)(/.*|$.*)
        pathType: Prefix
status:
  loadBalancer: {}
EOF
```

```bash
kubectl apply -f minio-ingress.yml -f nginx-ingress.yml
```
```
ingress.networking.k8s.io/minio-ingress configured
ingress.networking.k8s.io/nginx-ingress created
```

Test Ingress
```bash
curl -D - -s -o /dev/null "http://$(minikube ip)"

HTTP/1.1 200 OK
Date: Mon, 02 May 2022 21:49:32 GMT
Content-Type: text/html
Content-Length: 1356
Connection: keep-alive
Accept-Ranges: bytes
Last-Modified: Mon, 09 May 2022 21:49:32 GMT
Vary: Accept-Encoding
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-Xss-Protection: 1; mode=block


curl -D - -s -o /dev/null "http://$(minikube ip)/web"

HTTP/1.1 200 OK
Date: Mon, 02 May 2022 21:49:36 GMT
Content-Type: text/html
Content-Length: 615
Connection: keep-alive
Last-Modified: Mon, 25 May 2022 20:53:52 GMT
ETag: "61f01158-267"
Accept-Ranges: bytes
```

## 3.3 Create deploy with emptyDir save data to mountPoint emptyDir, delete pods, check data.

Creates the base file
```bash
kubectl create deployment empty-dir-deploy --image=nginx --replicas=1 --dry-run=client -o yaml | grep -v creationTimestamp > deployment-emptyDir.yml
```

The file after changes
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: test-empty-dir
  name: test-empty-dir
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.21-alpine
        name: nginx
        resources:
          requests:
            cpu: "0.1"
            memory: "64Mi"
          limits:
            cpu: "0.2"
            memory: "128Mi"
        volumeMounts:
        - mountPath: /raid10
          name: raid
          readOnly: false
      - image: busybox:1.35.0
        name: busybox
        command: ["sh", "-c", "sleep 5000"]
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
        volumeMounts:
        - mountPath: /raid10
          name: raid
          readOnly: false
      volumes:
      - name: raid
        emptyDir:
          medium: Memory
          sizeLimit: 64Mi
status: {}
```

Some test emptyDir
```bash
kubectl apply -f deployment-emptyDir.yml
```
```
kubectl exec -it test-empty-dir-796cb797d4-b88bw -c nginx -- touch /raid10/{test1.txt,test2.txt}
kubectl exec -it test-empty-dir-796cb797d4-s9442 -c nginx -- ls /raid10/
```
test1.txt  test2.txt
```
kubectl exec -it test-empty-dir-796cb797d4-s9442 -c busybox -- ls /raid10/
```
test1.txt  test2.txt
````
kubectl scale deployment test-empty-dir --replicas 0
```
deployment.apps/test-empty-dir scaled

```
kubectl scale deployment test-empty-dir --replicas 1
```
deployment.apps/test-empty-dir scaled

```
kubectl exec -it test-empty-dir-796cb797d4-592mc -c nginx -- ls /raid10/
```
