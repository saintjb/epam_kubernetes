# 1 In Minikube in namespace kube-system, there are many different pods running. Your task is to figure out who creates them, and who makes sure they are running (restores them after deletion).
Created script info.sh
```
./info.sh
```
<img width="909" alt="Снимок экрана 2022-04-28 в 16 17 35" src="https://user-images.githubusercontent.com/48727494/165769997-7dbea40c-3a7c-4ddc-a454-276be8c0838f.png">

#2 Implement Canary deployment of an application via Ingress. Traffic to canary deployment should be redirected if you add "canary:always" in the header, otherwise it should go to regular deployment. Set to redirect a percentage of traffic to canary deployment.
## Created and applyed configmaps (nginx, canary)
```
kubectl apply -f configmap-main.yaml
kubectl apply -f configmap-canary.yaml
```
Result:
<img width="536" alt="Снимок экрана 2022-04-28 в 19 04 57" src="https://user-images.githubusercontent.com/48727494/165770871-789a6fe5-a41d-49f4-99d1-a8c1316c85fe.png">

## Applyed deployments 
```
kubectl apply -f deployment-main.yaml
kubectl apply -f deployment-canary.yaml
```
Result:
<img width="667" alt="Снимок экрана 2022-04-28 в 19 10 05" src="https://user-images.githubusercontent.com/48727494/165772073-8bc16544-ee52-4dde-91a6-bc04ce90e0da.png">

## Create Services
```
kubectl apply -f service-main.yaml
kubectl apply -f service-canary.yaml
```
Result:
<img width="686" alt="Снимок экрана 2022-04-28 в 19 31 25" src="https://user-images.githubusercontent.com/48727494/165776445-fd2dc07f-818c-4176-90c9-f0626112a1d4.png">

## Create ingress
```
kubectl apply -f ingress-main.yaml
kubectl apply -f ingress-canary.yaml
```
Result:
<img width="668" alt="Снимок экрана 2022-04-28 в 19 33 23" src="https://user-images.githubusercontent.com/48727494/165776713-21912ce0-ab58-463e-ac27-5bf906d28d83.png">

# Test
## Normal work
```
curl --silent http://127.0.0.1 | grep head
```
```
<head><font color="red">main</head>
<head><font color="yellow">canary</head>
<head><font color="red">main</head>
<head><font color="red">main</head>
```
## With canary:always
```
curl -H "canary: always" --silent http://127.0.0.1 | grep head
```
```
<head><font color="yellow">canary</head>
<head><font color="yellow">canary</head>
<head><font color="yellow">canary</head>
```
