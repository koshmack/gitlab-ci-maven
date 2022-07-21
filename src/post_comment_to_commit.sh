#!/bin/bash

# Copyright © 2022 Synopsys, Inc.
#
# All rights reserved

# environment variables
gitlab_url=$CI_SERVER_URL
project_api_token=$MK_WEBGOAT_API_TOKEN
project_id=$CI_PROJECT_ID
sha=$CI_COMMIT_SHA

results_file=$1

readonly GITLAB_API_V4="/api/v4"
readonly POST_COMMENT_TO_COMMIT="/projects/$project_id/repository/commits/$sha/comments"

function post_comments () {
    notes=''
    for line in "$(cat $results_file)"
    do
    	notes+="$line"
    done
    res="$(curl -v -X POST -L $gitlab_url$GITLAB_API_V4$POST_COMMENT_TO_COMMIT \
        --header "PRIVATE-TOKEN: $project_api_token" \
        --form "note=$notes" \
        --form "line_type=new" \
        )"
}

# main entry
post_comments

exit 0