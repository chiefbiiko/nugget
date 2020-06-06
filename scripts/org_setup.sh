#!/usr/bin/env bash

# TODO
# - endless loop breaks

set -o pipefail

function help {
  printf "warning: run this once only for org initialization!
  
note: make sure to have access to the test and prod email accounts b4 running
    
usage: %s [-h, --help]
  --test_email TEST_EMAIL_ADDRESS
  --prod_email PROD_EMAIL_ADDRESS" \
  "$(basename "$0")"
}

while [[ $# -ne 0 ]]; do case $1 in
  --test_email) test_email=$2; shift 2;;
  --prod_email) prod_email=$2; shift 2;;
  -h|--help) help; exit 0;;
esac; done

if [[ -z "$prod_email" ]] || [[ -z "$test_email" ]]; then
  help; exit 0;
fi

printf "info: making sure no organization exists..\n"

if aws organizations describe-organization; then
  printf "error: organization already exists"
  exit 1
fi

exit 1

set -Eeu

printf "creating an organization..\n"

aws organizations create-organization --feature-set=ALL

root_ou_id="$(aws organizations list-roots --max-items=1 | jq '.Roots[].Id')"

printf "creating an engineering ou..\n"

engineering_ou_id="$(
  aws organizations create-organizational-unit \
    --parent-id=$root_ou_id \
    --name=Engineering \
    --output=json \
    --query='OrganizationalUnit.Id'
)"

printf "creating the test account..\n"

create_account_request_id="$(
  aws organizations create-account \
    --email="$test_email" \
    --account-name=test \
    --role-name=OrganizationAccountAccessRole \
    --output=json \
    --query='CreateAccountStatus.Id'
)"

while : ; do
  test_account_id="$(
    aws organizations describe-create-account-status \
      --create-account-request-id="$create_account_request_id" \
      --output=json \
      --query='CreateAccountStatus.AccountId'
  )"

  if [[ "$test_account_id" != "null" ]]; then
    break;
  else
    sleep 4.19
  fi
done

printf "creating the prod account..\n"

create_account_request_id="$(
  aws organizations create-account \
    --email="$prod_email" \
    --account-name=prod \
    --role-name=OrganizationAccountAccessRole \
    --output=json \
    --query='CreateAccountStatus.Id'
)"

while : ; do
  prod_account_id="$(
    aws organizations describe-create-account-status \
      --create-account-request-id=$create_account_request_id \
      --ouput=json \
      --query='CreateAccountStatus.AccountId'
  )"

  if [[ "$prod_account_id" != "null" ]]; then
    break;
  else
    sleep 4.19
  fi
done

printf "moving the rookie accounts into the engineering ou..\n"

aws organizations move-account \
  --account-id="$test_account_id" \
  --source-parent-id="$root_ou_id" \
  --destination-parent-id="$engineering_ou_id"

aws organizations move-account \
  --account-id="$prod_account_id" \
  --source-parent-id="$root_ou_id" \
  --destination-parent-id="$engineering_ou_id"

printf "aws account ids\ntest: %s\nprod: %s\n" \
  "$test_account_id" \
  "$prod_account_id"