## Architecture Overview
![Monitoring Infrastructure](/docs/monitoring_infrastructure.png "Monitoring Infrastructure")

## Deploying the Monitoring Stack

Before you begin, you'll need the following tools installed in your local development environment: 

- The `kubectl` command-line interface installed on your local machine and configured to connect to your cluster. You can read more about installing and configuring `kubectl` [in its official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- The [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) version control system installed on your local machine. To learn how to install git on Ubuntu 18.04, consult [How To Install Git on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-git-on-ubuntu-18-04)
- The Coreutils [base64](https://www.gnu.org/software/coreutils/manual/html_node/base64-invocation.html) tool installed on your local machine. If you're using a Linux machine, this will most likely already be installed. If you're using OS X, you can use `openssl base64`, which comes installed by default.

To start, clone this repo on your local machine, next, move into the cloned repository:

```shell
cd monitoring
```

### Seps automatically ran and set in `init.sh`:
Set the `APP_INSTANCE_NAME` and `NAMESPACE` environment variables, which will be used to configure a unique name for the stack's components and configure the Namespace into which the stack will be deployed: 

```shell
nano init.sh
APP_INSTANCE_NAME=node-monitoring
NAMESPACE=monitoring
```

Either run the `init.sh` script now (make sure `kubectl` is connected to the right context):

```shell
bash init.sh
```

Or set the `base64` command to base64-encode a secure Grafana password of your choosing:

```shell
GRAFANA_GENERATED_PASSWORD="$(echo -n 'your_grafana_password' | base64)"
```

If you're using OS X, you can use the `openssl base64` command which comes installed by default.

If you'd like to deploy the stack into a Namespace other than `node`, run the following command to create a new Namespace:

```shell
kubectl create namespace "$NAMESPACE"
```

Now, use `awk` and `envsubst` to fill in the `APP_INSTANCE_NAME`, `NAMESPACE`, and `GRAFANA_GENERATED_PASSWORD` variables in the repo's manifest files. After substituting in the variable values, the files will be combined into a master manifest file called `$APP_INSTANCE_NAME_manifest.yaml`.

```shell
awk 'FNR==1 {print "---"}{print}' manifest/* \
 | envsubst '$APP_INSTANCE_NAME $NAMESPACE $GRAFANA_GENERATED_PASSWORD' \
 > "${APP_INSTANCE_NAME}_manifest.yaml"
```

Now, use `kubectl apply -f` to apply the manifest and create the stack in the Namespace you configured:

```shell
kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml" --namespace "${NAMESPACE}"
```

You can use `kubectl get all` to monitor deployment status.

## Viewing the Grafana Dashboards

Once the stack is up and running, you can access Grafana by either patching the Grafana ClusterIP Service to create a Load Balancer, or by forwarding a local port. 

### Exposing the Grafana Service using a Load Balancer

To create a LoadBalancer Service for Grafana, use `kubectl patch` to update the existing Grafana Service in-place:

```shell
kubectl patch svc "$APP_INSTANCE_NAME-grafana" \
  --namespace "$NAMESPACE" \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

Once the DigitalOcean Load Balancer has been created and assigned an external IP address, you can fetch this external IP using the following commands:

```shell
SERVICE_IP=$(kubectl get svc $APP_INSTANCE_NAME-grafana \
  --namespace $NAMESPACE \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://${SERVICE_IP}/"
```

### Forwarding a Local Port to Access the Grafana Service

If you don't want to expose the Grafana Service externally, you can also forward local port 3000 into the cluster using `kubectl port-forward`. To learn more about forwarding ports into a Kubernetes cluster, consult [Use Port Forwarding to Access Applications in a Cluster](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

```shell
kubectl port-forward --namespace ${NAMESPACE} ${APP_INSTANCE_NAME}-grafana-0 3000
```

You can now access the Grafana UI locally at `http://localhost:3000/`.

At this point, you should be able to access the Grafana UI. To log in, use the default username `admin` (if you haven't modified the `admin-user` parameter), and password you configured above.

## Attribution

The manifests in this repo are heavily based on and modified from Google Cloud Platform's [click-to-deploy Prometheus solution](https://github.com/GoogleCloudPlatform/click-to-deploy/tree/master/k8s/prometheus). A manifest of modifications ([`changes.md`](https://github.com/do-community/doks-monitoring/blob/master/changes.md)) is included in this repo.
