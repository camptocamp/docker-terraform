#!/bin/bash

set -e

# Get the list of tags from a dockerhub repository (public or private)
get_tags_dhub () {
        local i=1
        local tags=''
	if [ "$2" == 'private' ]
	then
		local jwtoken=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'$3'", "password": "'$4'"}' 'https://hub.docker.com/v2/users/login/' | jq -r .token)
	fi
	local header=$([ "$2" == 'private' ] && echo Authorization: JWT $jwtoken || echo '')
        local page=$(curl -s -H "$header" "https://hub.docker.com/v2/repositories/$1/tags/?page=$i&page_size=100" | jq -r '.results|.[]|.name')
        while [ -n "$page" ]
        do
                tags="$tags $page"
                ((i++))
		page=$(curl -s -H "$header" "https://hub.docker.com/v2/repositories/$1/tags/?page=$i&page_size=100" | jq -r '.results|.[]|.name')
        done
        echo $tags
}

# Get the list of tags for an image in a github container registry
get_tags_ghcr () {
	local tags=$(curl -H "Authorization: OAuth $1" -s "https://ghcr.io/v2/$2/tags/list")
	if [[ $tags == *"NAME_UNKNOWN"* ]]
       	then
		echo ''
	else
		echo $tags | jq -r '.tags[]'
	fi
}

########################################################
# From 'hashicorp/terraform' to 'camptocamp/docker-terraform' #
########################################################

# Get list of new tags
new_tags=$(echo $(get_tags_dhub 'hashicorp/terraform') $(get_tags_ghcr $github_pat 'camptocamp/docker-terraform') $(get_tags_ghcr $github_pat 'camptocamp/docker-terraform') | tr ' ' '\n' | sort -V | uniq -u)

# Build from 1.6.0 forward
new_tags=$(echo ${new_tags/1.6.0//} | cut -d/ -f2)

# Build new images only if there are new tags
for j in $new_tags
do
	docker build --build-arg TAG=$j -t 'ghcr.io/camptocamp/docker-terraform':$j .
        docker push 'ghcr.io/camptocamp/docker-terraform':$j
done
