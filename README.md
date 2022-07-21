# gitlab-ci-maven
## About this project
This project is a small showcase for the integration of Synopsys software integrity products with GitLab CI Pipeline.

## Features
Invocation of Coverity SAST\
Upload the scan results from Coverity to the GitLab commit comment

## Usage (not details)
1. git clone this project
2. Create a GitLab project in your GitLab instance
3. Set up GitLab CI Pipeline including the runner
4. Set up the following variables in your GitLab project > Settings > CI/CD > Variables
COV_CONNECT_AUTHKEY_PATH\
COV_CONNECT_URL\
COV_CREDENTIALS\
COV_PROJECT\
COV_STREAM\
COV_VERSION\
COV_RESULTS_OCCURRENCES_FILE\
COV_RESULTS_ISSUES_FILE\
<GITLAB_API_TOKEN_YOUR_PROJECT>\
5. Commit and push the cloned .gitlab-ci.yml file and scripts

## Prerequisite
1. Ideally, you own your own self-managed GitLab instance. Free-tier should be enough for now as no paid features for GitLab are used.
2. You are a licensed user of the used Synopsys products and you own credentials or tokens to access those licensed Synopsys products. 

## License
Distributed under the Apache 2.0 License. See LICENSE.txt for more information.
