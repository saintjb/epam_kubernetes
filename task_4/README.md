# Task 4
## Create users deploy_view and deploy_edit. Give the user deploy_view rights only to view deployments, pods. Give the user deploy_edit full rights to the objects deployments, pods.

Create private keys

```
openssl genrsa -out deploy_view.key 2048
openssl genrsa -out deploy_edit.key 2048
```

Create a certificate sign-request

```
 openssl req -new -key deploy_view.key -out deploy_view.csr -subj "/CN=deploy_view"
 openssl req -new -key deploy_edit.key -out deploy_edit.csr -subj "/CN=deploy_edit"
```

Sign certificates in Kubernetes CA

```
openssl x509 -req -in deploy_view.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out deploy_view.crt -days 500

openssl x509 -req -in deploy_edit.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out deploy_edit.crt -days 500
```

```
Signature ok
subject=/CN=deploy_view
Getting CA Private Key

Signature ok
subject=/CN=deploy_view
Getting CA Private Key
```
Create users
```
kubectl config set-credentials deploy_view --client-certificate=deploy_view.crt --client-key=deploy_view.key
kubectl config set-credentials deploy_edit --client-certificate=deploy_edit.crt --client-key=deploy_edit.key
```
```
User "deploy_view" set.
User "deploy_edit" set.
```
Set context
```
kubectl config set-context deploy_view --cluster=minikube --user=deploy_view
kubectl config set-context deploy_edit --cluster=minikube --user=deploy_edit
```
Apply roles
```
kubectl api-resources --sort-by name -o wide | grep clusterroles
kubectl create clusterrole deploy_view --verb=get,list,watch --resource=deployments,pods --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
kubectl create clusterrole deploy_edit --verb='*' --resource=deployments,pods --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
```
```
clusterrole.rbac.authorization.k8s.io/deploy_view created
clusterrole.rbac.authorization.k8s.io/deploy_edit created
```
Apply bindings
```
kubectl create clusterrolebinding deploy_view --clusterrole=deploy_view --user=deploy_view --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
kubectl create clusterrolebinding deploy_edit --clusterrole=deploy_edit --user=deploy_edit --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
```
```
clusterrolebinding.rbac.authorization.k8s.io/deploy_view created
clusterrolebinding.rbac.authorization.k8s.io/deploy_edit created
```
Check rules
```
kubectl describe clusterrole deploy_view
kubectl describe clusterrole deploy_edit
kubectl describe clusterrolebindings.rbac.authorization.k8s.io deploy_edit 
kubectl describe clusterrolebindings.rbac.authorization.k8s.io deploy_view
```
Results:
```
Name:         deploy_view
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources         Non-Resource URLs  Resource Names  Verbs
  ---------         -----------------  --------------  -----
  pods              []                 []              [get list watch]
  deployments.apps  []                 []              [get list watch]

Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources         Non-Resource URLs  Resource Names  Verbs
  ---------         -----------------  --------------  -----
  pods              []                 []              [*]
  deployments.apps  []                 []              [*]

Name:         deploy_edit
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  deploy_edit
Subjects:
  Kind  Name         Namespace
  ----  ----         ---------
  User  deploy_edit

Name:         deploy_view
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  deploy_view
Subjects:
  Kind  Name         Namespace
  ----  ----         ---------
  User  deploy_view
```
```
kubectl config use-context deploy_view
kubectl config get-contexts
```
```
CURRENT   NAME          CLUSTER    AUTHINFO      NAMESPACE
          deploy_edit   minikube   deploy_edit
*         deploy_view   minikube   deploy_view
          k8s_user      minikube   k8s_user
          minikube      minikube   minikube      default
```
```
kubectl get all
```
```
Error from server (Forbidden): replicationcontrollers is forbidden: User "deploy_view" cannot list resource "replicationcontrollers" in API group "" in the namespace "default"
Error from server (Forbidden): services is forbidden: User "deploy_view" cannot list resource "services" in API group "" in the namespace "default"
Error from server (Forbidden): daemonsets.apps is forbidden: User "deploy_view" cannot list resource "daemonsets" in API group "apps" in the namespace "default"
Error from server (Forbidden): replicasets.apps is forbidden: User "deploy_view" cannot list resource "replicasets" in API group "apps" in the namespace "default"
Error from server (Forbidden): statefulsets.apps is forbidden: User "deploy_view" cannot list resource "statefulsets" in API group "apps" in the namespace "default"
Error from server (Forbidden): horizontalpodautoscalers.autoscaling is forbidden: User "deploy_view" cannot list resource "horizontalpodautoscalers" in API group "autoscaling" in the namespace "default"
Error from server (Forbidden): cronjobs.batch is forbidden: User "deploy_view" cannot list resource "cronjobs" in API group "batch" in the namespace "default"
Error from server (Forbidden): jobs.batch is forbidden: User "deploy_view" cannot list resource "jobs" in API group "batch" in the namespace "default"
```
## Create namespace prod. Create users prod_admin, prod_view. Give the user prod_admin admin rights on ns prod, give the user prod_view only view rights on namespace prod.

Create namespace, users
```
kubectl create namespace prod
users=(prod_admin prod_view)

for i in ${users[@]}; do \
  openssl genrsa -out $i.key 2048 \
	&& openssl req -new -key $i.key \
	-out $i.csr \
	-subj "/CN=$i" \
	&& openssl x509 -req -in $i.csr \
	-CA ~/.minikube/ca.crt \
	-CAkey ~/.minikube/ca.key \
	-CAcreateserial \
	-out $i.crt -days 500 \
	&& kubectl config set-credentials $i \
	--client-certificate=$i.crt \
	--client-key=$i.key \
	&& kubectl config set-context $i \
	--cluster=minikube --user=$i; \
done
```
```
Signature ok
subject=/CN=prod_admin
Getting CA Private Key
User "prod_admin" set.
Context "prod_admin" created.
Generating RSA private key, 2048 bit long modulus
............................................+++
..............................................................+++
e is 65537 (0x10001)
Signature ok
subject=/CN=prod_view
Getting CA Private Key
User "prod_view" set.
Context "prod_view" created.
```
Apply roles
```
# https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/
kubectl api-resources --sort-by name -o wide | grep -E "^roles"

kubectl create role prod_admin --verb='*' --resource='*' --namespace=prod --dry-run=client -o yaml | grep -v creationTimestamp > role_prod_admin.yml

cat <<- EOF | tee role_prod_admin.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prod_admin
  namespace: prod
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
EOF

kubectl apply -f role_prod_admin.yml

kubectl create role prod_view --verb=get,list,watch --resource='*' --namespace=prod --dry-run=client -o yaml | grep -v creationTimestamp > role_prod_view.yml

cat <<- EOF | tee role_prod_view.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prod_view
  namespace: prod
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - get
  - list
  - watch
EOF

kubectl apply -f role_prod_view.yml
```
Apply bindings
```
kubectl api-resources --sort-by name -o wide | grep -E "^rolebindings"

kubectl create rolebinding prod_admin --role=prod_admin --user=prod_admin --namespace=prod --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
kubectl create rolebinding prod_view --role=prod_view --user=prod_view --namespace=prod --dry-run=client -o yaml | grep -v creationTimestamp | kubectl apply -f -
```
Result:
```
rolebinding.rbac.authorization.k8s.io/prod_admin created
rolebinding.rbac.authorization.k8s.io/prod_view created
```
Check roles, bindings
```
kubectl describe role {prod_admin,prod_view} -n prod
kubectl describe rolebindings {prod_admin,prod_view} -n prod
```
```
Name:         prod_admin
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [*]


Name:         prod_view
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [get list watch]
Name:         prod_admin
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  prod_admin
Subjects:
  Kind  Name        Namespace
  ----  ----        ---------
  User  prod_admin


Name:         prod_view
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  prod_view
Subjects:
  Kind  Name       Namespace
  ----  ----       ---------
  User  prod_view
```

## Create sa-namespace-admin
```
kubectl create serviceaccount sa-namespace-admin
```
```
serviceaccount/sa-namespace-admin created
```
Check token
```
kubectl get serviceaccounts sa-namespace-admin -o yaml | grep secrets -A 1
```
```
secrets:
- name: sa-namespace-admin-token-22pm6
```
```
kubectl get secrets sa-namespace-admin-token-22pm6 -o yaml | grep token:
```
```
token: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNkltNVZNMDVCVDBsUlYxTk1WRGh6YWxaRVJVcHViMkppZEc0dFZETktiRk5IYnpCVk9FRTNaMmRaV0ZraWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUprWldaaGRXeDB...
```
Create role
```
cat <<- EOF | tee sa-role.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sa-admin-role
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
EOF
```
Bind role with sa
```
kubectl create rolebinding sa-admin-rolebind --role=sa-admin-role --serviceaccount=default:sa-namespace-admin
```
```
rolebinding.rbac.authorization.k8s.io/sa-admin-rolebind created
```
Set context
```
kubectl config set-context sa-namespace-admin --cluster=minikube --namespace=default --user=sa-namespace-admin
```
```
Context "sa-namespace-admin" created.
```
Check work of sa
```
kubectl config set-credentials sa-namespace-admin --token=$TOKEN
kubectl config use-context sa-namespace-admin

list=(pods deployments replicasets ingresses roles)

for i in ${list[@]}; do \
  printf "  How I create %s? -> %s\n" "$i" "$(kubectl auth can-i create $i --namespace default)"; done
  Can I create pods? -> yes
  Can I create deployments? -> yes
  Can I create replicasets? -> yes
  Can I create ingresses? -> yes
  Can I create roles? -> yes

for i in ${list[@]}; do \
  printf "  How I create %s? -> %s\n" "$i" "$(kubectl auth can-i create $i --namespace kube-system)"; done
  Can I create pods? -> no
  Can I create deployments? -> no
  Can I create replicasets? -> no
  Can I create ingresses? -> no
```