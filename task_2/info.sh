#!/bin/bash
for element in $(kubectl get pods -n kube-system | grep -v NAME | awk '{print $1}')
do
echo pod: $element
kubectl describe pods/$element --namespace kube-system | grep "Controlled 
By:"
done
