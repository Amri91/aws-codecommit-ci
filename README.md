# aws-codecommit-ci

This automates common code review chores for AWS CodeCommit repositories.

## To deploy

```bash
#!/bin/bash

set -eufo pipefail

aws configure # Alternatively, set AWS_PROFILE and AWS_DEFAULT_REGION
git clone git@github.com:Amri91/aws-codecommit-ci.git && cd aws-codecommit-ci && ./deploy.sh
```

## To remove

```bash
./remove.sh
```

## CodeBuild custom environment variables

- repositoryName
- pullRequestId
- destinationCommit
- sourceCommit
- destinationReference
- sourceReference

## Tips

- If you have too many repositories, the AWS_TRACKED_REPOSITORIES variable will be difficult to maintain. Put the ARNs in a JSON file and use jq -r '. | join(",")' tracked-repositories.json in deploy.sh instead.
- If your tests require too many things to install, you can use a custom ECR image instead of the standard AWS provided one.
- If your script becomes too complicated, you can put it in a different repository and reference it in the CodeBuild instead.

## Example tests

### CFN LINT

Runs cfn-lint.

> The target repository must have cfn-lint config file. 

```bash
echo "Running cfn-lint."
lintResult=0
cfn-lint || lintResult=$?
[ $lintResult -ne 0 ] && echo "cfn-lint check did not pass."
checks+=("$lintResult")
```

### CFN GUARD

Checks all templates against common guard rules.

> Templates are in the cf directory and the rules are in a CodeBuild source.

```bash
# CFN guard checks
echo "Checking CFN global guard rules"
for template in cf/*.json; do
  guardResult=0
  cfn-guard check --rule_set $CODEBUILD_SRC_DIR/cfn.ruleset --template $template || guardResult=$?
  checks+=("$guardResult")
  [ "$guardResult" -ne 0 ] && echo "Guard check failed for: $template"
done
```

### GIT

Revokes outdated PRs.

```bash
echo "Checking rev list."
isOld=$(git rev-list --right-only --count origin/"$sourceBranch"...origin/"$destinationBranch")
checks+=("$isOld")
[ "$isOld" -ne 0 ] && echo "This branch is behind the destination branch, update it."
```