# Crossplane Azure Demo
## Create AKS cluster
```bash
terraform init
terraform apply
```

## Connect to AKS cluster
```bash
az aks get-credentials --resource-group crossplane-demo-rg --name crossplane-demo-aks
```

## Install Crossplane
### Add and install Helm Chart
```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane
```

### Check Crossplane installation status
```bash
kubectl get pods -n crossplane-system
kubectl get deployments -n crossplane-system
```

## Install Crossplane Azure Provider
```bash
kubectl apply -f manifests/provider-azure.yaml
kubectl get providers
```

## Create Azure Provider Secret
```bash
az ad sp create-for-rbac --sdk-auth --role Owner --scopes /subscriptions/$SUBSCRIPTION_ID | tee azure-credentials.json
kubectl create secret generic azure-secret -n crossplane-system --from-file=creds=./azure-credentials.json
kubectl describe secret azure-secret -n crossplane-system
kubectl apply -f manifests/default-provider-config.yaml
```

## Create Azure Resource Group
```bash
kubectl apply -f manifests/azure-resource-group.yaml
kubectl get resourcegroups
```

## Create Azure Kubernetes Cluster
```bash
kubectl apply -f manifests/azure-kubernetes-cluster.yaml
kubectl get kubernetesclusters
```

## Clean up
```bash
rm azure-credentials.json
az group delete --subscription $SUBSCRIPTION_ID --name $RESOURCE_GROUP_NAME --yes
az ad sp delete --id $(jq -r .clientId azure-credentials.json)
```
