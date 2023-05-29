# Set environment variables
```bash
SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
BASE_NAME="crossplane-azure-demo"
RESOURCE_GROUP_NAME="$BASE_NAME-rg"
AKS_NAME="$BASE_NAME-aks"
LOCATION="westeurope"
```

# Create AKS cluster
## Create Resource Group
```bash
az group create --subscription $SUBSCRIPTION_ID --name $RESOURCE_GROUP_NAME --location $LOCATION
```
## Create AKS cluster
```bash
az deployment group create --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP_NAME --template-file bicep/main.bicep --parameters baseName=$BASE_NAME location=$LOCATION
```

# Connect to AKS cluster
## Create AKS Cluster Admin role assignment
```bash
az role assignment create --role "Azure Kubernetes Service RBAC Cluster Admin" --assignee $(az ad signed-in-user show --query id -o tsv) --scope /subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP_NAME/providers/Microsoft.ContainerService/managedClusters/$AKS_NAME
```
## Get AKS cluster credentials
```bash
az aks get-credentials --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP_NAME --name $AKS_NAME
```

# Install Crossplane
## Add and install Helm Chart
```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane --namespace crossplane-system --create-namespace crossplane-stable/crossplane --set "args={--enable-management-policies}"
```
## Check Crossplane installation status
```bash
kubectl get pods -n crossplane-system
kubectl get deployments -n crossplane-system
```

# Install Crossplane Azure Provider
```bash
kubectl apply -f manifests/provider-azure.yaml
kubectl get providers
```

# Create Azure Provider Secret
```bash
az ad sp create-for-rbac --sdk-auth --role Owner --scopes /subscriptions/$SUBSCRIPTION_ID | tee azure-credentials.json
kubectl create secret generic azure-secret -n crossplane-system --from-file=creds=./azure-credentials.json
kubectl describe secret azure-secret -n crossplane-system
kubectl apply -f manifests/default-provider-config.yaml
```

# Create Azure Resource Group
```bash
kubectl apply -f manifests/azure-resource-group.yaml
kubectl get resourcegroups
```

# Create Azure Kubernetes Cluster
```bash
kubectl apply -f manifests/azure-kubernetes-cluster.yaml
kubectl get kubernetesclusters
```

# Clean up
```bash
rm azure-credentials.json
az group delete --subscription $SUBSCRIPTION_ID --name $RESOURCE_GROUP_NAME --yes
az ad sp delete --id $(jq -r .clientId azure-credentials.json)
```
