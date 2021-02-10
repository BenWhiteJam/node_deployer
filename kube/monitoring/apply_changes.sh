export APP_INSTANCE_NAME=node-monitoring
export NAMESPACE=monitoring

export GRAFANA_GENERATED_PASSWORD="$(echo -n "grafana" | base64)"
awk 'FNR==1 {print "---"}{print}' ./manifest/* \
 | envsubst '$APP_INSTANCE_NAME $NAMESPACE $GRAFANA_GENERATED_PASSWORD' \
  > "./${APP_INSTANCE_NAME}_manifest.yaml"

# Updates the deployment
#kubectl -n "$NAMESPACE" apply -f "./${APP_INSTANCE_NAME}_manifest.yaml"
