# GCP Monitor & Stateless Grafana

This repository is an example of how to visualize data from [Google Cloud Monitoring](https://cloud.google.com/monitoring) (formerly known as Stackdriver) using [Grafana](https://grafana.com) in a stateless fashion with provisioned dashboards and datasources. The advantage of this approach is that you can access your Grafana dashboards through Docker containers even on your local machine, and if you shut it down and restart you'd still have access to the same data and dashboards. This also makes GitOps possible by putting the dashboard configurations under version control.

This approach is inspired by another [repo](https://github.com/meken/azure-monitor-grafana).

## Prepare the access keys

In order to access monitoring data on the Google Cloud Platform we'll create a new service account and configure access for that following the instructions from the Grafana [docs](https://grafana.com/docs/grafana/latest/datasources/google-cloud-monitoring/google-authentication/).

First step is to create the service account.

```shell
PROJECT_ID=...  # set to the project to be monitored
SA_GRAFANA=sac-grafana

gcloud iam service-accounts create $SA_GRAFANA \
    --display-name="Grafana Monitoring" \
    --project=$PROJECT_ID
```

Assign permissions to the newly created service account.

```shell
IAM_ACCOUNT="$SA_GRAFANA@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$IAM_ACCOUNT" \
    --role="roles/monitoring.viewer"
```

Now let's create a key (assuming that your organizational policies allow that, if not you can turn `constraints/iam.disableServiceAccountKeyCreation` off, or opt for the alternative GCE authentication which requires you to run the Grafana instance on GCE).

```shell
KEY_FILE="$SA_GRAFANA-key.json"

gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$IAM_ACCOUNT \
    --project=$PROJECT_ID
```

Once we've got the key file we can start setting up the configuration. First let's put the secret in an environment variable so we can pass it to the `docker run` command. Since the private key contains newlines which we need to preserve, this needs some special care, all credit for the magic below goes to this [post](https://unix.stackexchange.com/questions/369972/how-can-i-set-an-environment-variable-which-contains-newline-characters).

```shell
SA_SECRET=`jq -r '.private_key' $KEY_FILE`
```

## Build and run the image

The process of building and running the Docker image is pretty straight forward. All you need to do is to pass the environment variables that have been created in the previous steps to the container.

```shell
IMG_TAG=gcp-monitor-grafana:1
docker build -t $IMG_TAG .
docker run -d -p 3000:3000 \
    -e PROJECT_ID="$PROJECT_ID" \
    -e SA_GRAFANA="$IAM_ACCOUNT" \
    -e SA_SECRET="$SA_SECRET" \
    -e GF_LOG_MODE=file \
    -e GF_LOG_LEVEL=debug \
    $IMG_TAG
````


