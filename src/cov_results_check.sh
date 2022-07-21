#!/bin/bash

# Copyright © 2022 Synopsys, Inc.
#
# All rights reserved
#
# Remark: Dependency to jq for handling JSON data

# environment variables set in GitLab CI project settings
cov_url=$COV_CONNECT_URL
credentials=$COV_CREDENTIALS
project=$COV_PROJECT
occurrences_file=$COV_RESULTS_OCCURRENCES_FILE
issues_file=$COV_RESULTS_ISSUES_FILE

readonly API_ISSUE_OCCURRENCES="/api/v2/issueOccurrences/search?"
readonly API_ISSUES="/api/v2/issues/search?"
# TODO: Consider paging instead of the fixed row count
readonly PARAM_ISSUE_OCCURRENCES="includeColumnLabels=true&locale=en_us&offset=0&queryType=bySnapshot&rowCount=500&sortOrder=asc"
readonly PARAM_ISSUES="includeColumnLabels=true&locale=en_us&offset=0&queryType=bySnapshot&rowCount=500&sortOrder=asc"
# Decorated header string for nicely shown comment!
readonly OCCURRENCES_HEADER="# Coverity Results: number of occurrences for each impact level"
readonly COVERITY_LINK="## [Link to Coverity]($COV_CONNECT_URL)"
readonly ISSUES_HEADER="# Coverity Results: High Impact Cid, Checker, Category, Type, CWE, First Detected, File, Function, Count"

function get_issue_occurrences () {
    # Get cid and displayImpact
    json_data="{\
        \"filters\": [\
            {\
                \"columnKey\": \"project\",\
                \"matchMode\": \"oneOrMoreMatch\",\
                \"matchers\": [\
                    {\
                        \"class\": \"Project\",\
                        \"name\": \"%s\",\
                        \"type\": \"nameMatcher\"\
                    }\
               ]\
            }\
        ],\
        \"columns\": [\
            \"cid\",\
            \"displayImpact\"\
        ]\
    }"
    json_data_raw="$(printf "$json_data", "$project")"

    res="$(curl -X POST -L $cov_url$API_ISSUE_OCCURRENCES$PARAM_ISSUE_OCCURRENCES \
        --user "$credentials" \
        --header 'Content-Type: application/json' \
	    --header 'Accept: application/json' \
        --data-raw "$json_data_raw" \
        )"
        
    # Count number of each impact level and return to the caller
    columns="$(jq -cr '.rows' <<< $res)"
    high="$(printf "$columns" | grep -io high | wc -l)"
    medium="$(printf "$columns" | grep -io medium | wc -l)"
    low="$(printf "$columns" | grep -io low | wc -l)"
    audit="$(printf "$columns" | grep -io audit | wc -l)"
    # Decorated lines here too for a little bit nicely displayed comments
    printf "%s\n" "## Number of impact High occurrences is $high"
    printf "%s\n" "## Number of impact Medium occurrences is $medium"
    printf "%s\n" "## Number of impact Low occurrences is $low"
    printf "%s\n" "## Number of impact Audit occurrences is $audit"
}

# TODO (Future consideration): Maybe to upload to GitLab Issues or Project Issue Board
function get_high_issues () {
    # Get cid, displayCategory, cwe and displayType only for High Impact issues
    json_data="{\
        \"filters\": [\
            {\
                \"columnKey\": \"project\",\
                \"matchMode\": \"oneOrMoreMatch\",\
                \"matchers\": [\
                    {\
                        \"class\": \"Project\",\
                        \"name\": \"%s\",\
                        \"type\": \"nameMatcher\"\
                    }\
               ]\
            },\
            {\
                \"columnKey\": \"displayImpact\",\
                \"matchMode\": \"oneOrMoreMatch\",\
                \"matchers\": [\
                    {\
                        \"key\": \"High\",
                        \"type\": \"keyMatcher\"
                    }\
                ]\
            }\
        ],\
        \"columns\": [\
            \"cid\",\
            \"checker\",\
            \"displayCategory\",\
            \"displayType\",\
            \"cwe\",\
            \"firstDetected\",\
            \"displayFile\",\
            \"displayFunction\",\
            \"occurrenceCount\"\
        ]\
    }"

    json_data_raw="$(printf "$json_data", "$project")"

    res="$(curl -X POST -L $cov_url$API_ISSUES$PARAM_ISSUES \
        --user "$credentials" \
        --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        --data-raw "$json_data_raw" \
    )"

    json_strings="$(jq -c '.rows | .[]' <<< $res)"
    printf "%s\n" "$json_strings"
}

# main entry
# Issue occurrences report
printf "%s\n" "$OCCURRENCES_HEADER" > $occurrences_file
printf "%s\n" "$COVERITY_LINK" >> $occurrences_file
printf "%s\n" "$(get_issue_occurrences)" >> $occurrences_file

# Issue with high impact report
printf "%s\n" "$ISSUES_HEADER" > $issues_file
# Print out fetched Coverity cid, category, cwe and type
# Remark: outer loop to handle a json string for each one of the Coverity "issue" while inner
# loop to handle a pair of json, e.g. "cid: 12345", with removal of 'x0a' from each json string
while IFS= read -r json_string; do
    idx=0
    line_out="## "
    while IFS= read -r json_pair; do
        line_out="$line_out$(jq -r '.key' <<< $json_pair): "
        line_out="$line_out$(jq -r '.value' <<< $json_pair), "
        if [[ idx -eq 8 ]]; then
            printf "%s\n" "${line_out::-2}" >> $issues_file
            break
        else
            (( idx++ ))
        fi
    done <<< "$(jq -c '.[]' <<< $json_string)"
done <<< "$(get_high_issues)"

exit 0