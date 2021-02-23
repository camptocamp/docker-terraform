#!/bin/bash

set -e

# Get the list of tags from a repo - usage: get_tags <token> <repo>
get_tags () {
        local i=1
        local tags=''
        local page=$(curl -s -H "Authorization: JWT $1" "https://hub.docker.com/v2/repositories/$2/tags/?page=$i&page_size=100" | jq -r '.results|.[]|.name')
        while [ -n "$page" ]
        do
                tags="$tags $page"
                ((i++))
                page=$(curl -s -H "Authorization: JWT $1" "https://hub.docker.com/v2/repositories/$2/tags/?page=$i&page_size=100" | jq -r '.results|.[]|.name')
        done
        echo $tags
}

# Get token
token=$(curl -s -H 'Content-Type: application/json' -X POST -d '{"username": "'$uname'", "password": "'$upass'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# Get list of new tags
new_tags=$(echo $(get_tags $token 'hashicorp/terraform') $(get_tags $token $dest_repo) $(get_tags $token $dest_repo) | tr ' ' '\n' | sort -V | uniq -u)

# Comment the following line to get version prior to 0.13.0
new_tags=$(echo ${new_tags/0.12.30//} | cut -d/ -f2)

# Build new images only if there are new tags
if [ -n "$new_tags" ]
then
        for j in $new_tags
        do
                docker build --build-arg TAG=$j -t $dest_repo:$j .
                docker push $dest_repo:$j
        done
fi
