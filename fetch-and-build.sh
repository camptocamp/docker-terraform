#!/bin/bash

# Example for the Docker Hub V2 API
# Returns all images and tags associated with a Docker Hub organization account.
# Requires 'jq': https://stedolan.github.io/jq/
# TODO update description

# set username, password, and organization
UNAME="USERNAME" # TODO replace
UPASS="PASSWORD" # TODO replace
SOURCE_ORG="hashicorp"
SOURCE_REPO="terraform"
DEST_ORG="DESTINATION" # TODO replace
DEST_REPO="terraform"

# -------

set -e
echo

# get token
echo "Retrieving token ..."
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# output images & tags
echo
echo "Images and tags in repository: ${SOURCE_ORG}/${SOURCE_REPO}"
echo

IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${SOURCE_ORG}/${SOURCE_REPO}/tags/?page_size=100 | jq -r '.results|.[]|.name')
for j in ${IMAGE_TAGS}
do
  # TODO add checkpoint: check wether the customized image already exists - make sure only the new images are built and pushed
  echo "Building image ${DEST_ORG}/${DEST_REPO}:${j}"
  docker build --build-arg REPO="${SOURCE_REPO}:${j}" -t ${DEST_ORG}/${DEST_REPO}:${j} .
  # TODO add push command
done
