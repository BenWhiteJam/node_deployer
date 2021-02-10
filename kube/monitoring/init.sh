export APP_INSTANCE_NAME=node-monitoring
export NAMESPACE=monitoring

kubectl delete namespace "$NAMESPACE"
kubectl create namespace "$NAMESPACE"

export GRAFANA_GENERATED_PASSWORD="$(echo -n "grafana" | base64)"
awk 'FNR==1 {print "---"}{print}' ./manifest/* \
 | envsubst '$APP_INSTANCE_NAME $NAMESPACE $GRAFANA_GENERATED_PASSWORD' \
  > "./${APP_INSTANCE_NAME}_manifest.yaml"

kubectl -n "$NAMESPACE" apply -f "./kube/monitoring/${APP_INSTANCE_NAME}_manifest.yaml"

kubectl -n "$NAMESPACE" patch svc "$APP_INSTANCE_NAME-grafana"  -p '{"spec": {"type": "LoadBalancer"}}'

helm ls -a --all-namespaces | awk 'NR > 1 { print  "-n "$2, $1}' | xargs -L1 helm delete
helm init

# Fetch loki helm ref and repo
helm repo add loki https://grafana.github.io/loki/charts
helm repo update
#https://grafana.com/docs/grafana/latest/features/datasources/loki/
helm upgrade --install loki --namespace=$NAMESPACE loki/loki-stack --set fluent-bit.enabled=true,promtail.enabled=true,loki.persistence.enabled=true,loki.persistence.size=100Gi,config.table_manager.retention_deletes_enabled=true,config.table_manager.retention_period=720h

kubectl -n "$NAMESPACE" get service "$APP_INSTANCE_NAME-grafana" -w

SERVICE_IP=$(kubectl -n "$NAMESPACE" get svc $APP_INSTANCE_NAME-grafana --output jsonpath='{.status.loadBalancer.ingress[0].ip}') \
  echo "http://${SERVICE_IP}/"

# Node benchmark instance build, tag image, push to remote image repo,
#kubectl delete namespace $(kubectl get namespaces --output=jsonpath='{.items[-1].metadata.name}')
#docker build -t kubemgmt -f docker/kubeManager/Dockerfile .
#docker tag kubemgmt gcr.io/node-testnets-282010/kubemanager:latest
#docker push gcr.io/node-testnets-282010/kubemanager:latest
