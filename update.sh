#!/bin/bash

set -e

# Get token
token=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${uname}'", "password": "'${upass}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# Retrieve list of all tags from repo hashicorp/terraform
source_tags=$(curl -s -H "Authorization: JWT ${token}" https://hub.docker.com/v2/repositories/hashicorp/terraform/tags/?page_size=100 | jq -r '.results|.[]|.name')

# Get list of tags from destination repo
dest_tags=$(curl -s -H "Authorization: JWT ${token}" https://hub.docker.com/v2/repositories/${dest_repo}/tags/?page_size=100 | jq -r '.results|.[]|.name')

# Get list of new tags
new_tags=$(echo ${source_tags[@]} ${dest_tags[@]} | tr ' ' '\n' | sort -V | uniq -u)

# Comment this to get tags prior to 0.13.0 - first sync
new_tags=$(echo ${new_tags[@]/0.12.30//} | cut -d/ -f2)

# Build new images only if there are new tags
if [ ! -z "$new_tags" ]
then
        for j in ${new_tags}
        do
                docker build --build-arg TAG="${j}" -t ${dest_repo}:${j} .
                docker push ${dest_repo}:${j}
        done
fi
