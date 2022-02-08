gcloud container clusters create mhssui \
 --node-taints node.cilium.io/agent-not-ready=true:NoSchedule --zone europe-west6-a
