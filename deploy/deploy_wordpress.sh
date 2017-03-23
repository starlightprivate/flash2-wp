#!/bin/bash
set -e

export IMAGE_TAG="${CI_COMMIT_ID}"
export IMAGE_NAME="wordpress"
export APPLICATION_NAME="wordpress"

# authenticate to google cloud
codeship_google authenticate

# set compute zone 
gcloud config set compute/zone ${CLUSTER_ZONE}

# set kubernetes cluster
gcloud container clusters get-credentials "${CLUSTER_NAME}"

# install envsubst
apt-get install gettext-base -y

# update kubernetes Deployment file
envsubst < deploy/kubernetes/wordpress_deployment.yml.template > deploy/kubernetes/wordpress_deployment.yml

cat deploy/kubernetes/wordpress_deployment.yml

# deploy
deployment_flag=$(GOOGLE_APPLICATION_CREDENTIALS=/keyconfig.json kubectl get deployment -l app=${APPLICATION_NAME})

if [[ -z "$deployment_flag" ]]; then
  echo "Create new deployment and service for ${APPLICATION_NAME}"
  GOOGLE_APPLICATION_CREDENTIALS=/keyconfig.json kubectl create -f deploy/kubernetes/wordpress_deployment.yml
  GOOGLE_APPLICATION_CREDENTIALS=/keyconfig.json kubectl expose deployment ${APPLICATION_NAME} --name=${APPLICATION_NAME} --port=80 --type="NodePort"
else
  echo "Rolling update for ${APPLICATION_NAME}"
  GOOGLE_APPLICATION_CREDENTIALS=/keyconfig.json kubectl apply -f deploy/kubernetes/wordpress_deployment.yml
fi
