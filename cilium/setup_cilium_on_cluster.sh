# azure cilium install --azure-resource-group "${AZURE_RESOURCE_GROUP}"
cilium install

cilium status --wait

cilium hubble enable --ui

cilium status --wait

hubble status

cilium hubble ui
