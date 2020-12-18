#!/bin/bash

set -eufo pipefail

# Updating approval rule via script because it is not supported yet by CloudFormation.
name=my-default-approval-rule
template="{\"Version\": \"2018-11-08\",\"Statements\": [{\"Type\": \"Approvers\",\"NumberOfApprovalsNeeded\": 2,\"ApprovalPoolMembers\": [\"*\"]}]}"
aws codecommit create-approval-rule-template --approval-rule-template-name $name --approval-rule-template-description "2 approvals for all PRs." --approval-rule-template-content "$template" || true
aws codecommit update-approval-rule-template-content --approval-rule-template-name $name --new-rule-content "$template"
repositoryNames=$(echo $AWS_TRACKED_REPOSITORIES | sed -e 's/arn:aws:codecommit:.*://g')
IFS=',' read -ra repositories <<< "$repositoryNames"
for repository in "${repositories[@]}"; do
  aws codecommit associate-approval-rule-template-with-repository --approval-rule-template-name $name --repository-name $repository
done

# Updating the reviewer stack
aws cloudformation deploy --template-file ./reviewer.yml --stack-name reviewer --parameter-overrides TrackedRepositories=$AWS_TRACKED_REPOSITORIES --tags Application=Reviewer --capabilities CAPABILITY_NAMED_IAM