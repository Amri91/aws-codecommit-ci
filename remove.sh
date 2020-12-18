#!/bin/bash

set -eufo pipefail

name=my-default-approval-rule

repositoryNames=$(aws codecommit list-repositories-for-approval-rule-template --approval-rule-template-name $name --query repositoryNames | jq -r 'join(",")')

echo "Disassociating rules."

IFS=',' read -ra repositories <<< "$repositoryNames"
for repository in "${repositories[@]}"; do
  aws codecommit disassociate-approval-rule-template-from-repository --approval-rule-template-name $name --repository-name $repository
done

echo "Delete the approval rule."
aws codecommit delete-approval-rule-template --approval-rule-template-name $name || true

echo "Deleting the template."
aws cloudformation delete-stack --stack-name reviewer

echo "Done."