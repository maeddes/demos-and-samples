#z !/bin/bash

set -eux

export NAME="mhs-aks-cilium"
export AZURE_RESOURCE_GROUP="mhs-aks-cilium-group"
az group create --name "${AZURE_RESOURCE_GROUP}" -l westeurope

# Create AKS cluster
az aks create \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${NAME}" \
  --network-plugin azure \
  --node-count 1

# Get name of initial system node pool
nodepool_to_delete=$(az aks nodepool list \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${NAME}" \
  --output tsv --query "[0].name")

# Create system node pool tainted with `CriticalAddonsOnly=true:NoSchedule`
az aks nodepool add \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${NAME}" \
  --name systempool \
  --mode system \
  --node-count 1 \
  --node-taints "CriticalAddonsOnly=true:NoSchedule" \
  --no-wait

# Create user node pool tainted with `node.cilium.io/agent-not-ready=true:NoSchedule`
az aks nodepool add \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${NAME}" \
  --name userpool \
  --mode user \
  --node-count 2 \
  --node-taints "node.cilium.io/agent-not-ready=true:NoSchedule" \
  --no-wait

# Delete the initial system node pool
az aks nodepool delete \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --cluster-name "${NAME}" \
  --name "${nodepool_to_delete}" \
  --no-wait

# Get the credentials to access the cluster with kubectl
# az aks get-credentials --resource-group "${AZURE_RESOURCE_GROUP}" --name "${NAME}"

echo y|az aks get-credentials --name "${NAME}" --resource-group "${AZURE_RESOURCE_GROUP}"

cilium install --azure-resource-group "${AZURE_RESOURCE_GROUP}"

cilium status --wait

cilium hubble enable
cilium hubble enable --ui

cilium status --wait

cilium hubble port-forward&

hubble status


