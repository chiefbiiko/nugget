#!/usr/bin/env bash

set -uo pipefail

DOMAIN=$1

cat <<EOF
warning: $0 is intended to be run once for initialization only!
note: make sure the (test.)$DOMAIN@gmail.com email adresses exist b4 running
EOF

printf "info: making sure no organization exists..\n"

if aws organizations describe-organization; then
  printf "error: organization already exists"
  exit 1
fi

exit 1

set -Ee

printf "creating an organization..\n"

aws organizations create-organization --feature-set=ALL

root_ou_id=$(aws organizations list-roots --max-items=1 | jq '.Roots[].Id')

printf "creating an engineering ou..\n"

engineering_ou_id=$(
  aws organizations create-organizational-unit \
    --parent-id=$root_ou_id \
    --name=Engineering \
    | \
    jq '.OrganizationalUnit.Id'
)

printf "creating the test account..\n"

create_account_request_id=$(
  aws organizations create-account \
    --email="test.$DOMAIN@gmail.com" \
    --account-name=test \
    --role-name=OrganizationAccountAccessRole \
    | \
    jq 'CreateAccountStatus.Id'
)

while : ; do
  test_account_id=$(
    aws organizations describe-create-account-status \
      --create-account-request-id=$create_account_request_id \
      | \
      jq '.CreateAccountStatus.AccountId'
  )

  if [[ $test_account_id != null ]]; then
    break;
  else
    sleep 4.19
  fi
done

printf "creating the prod account..\n"

create_account_request_id=$(
  aws organizations create-account \
    --email="$DOMAIN@gmail.com" \
    --account-name=prod \
    --role-name=OrganizationAccountAccessRole \
    | \
    jq 'CreateAccountStatus.Id'
)

while : ; do
  prod_account_id=$(
    aws organizations describe-create-account-status \
      --create-account-request-id=$create_account_request_id \
      | \
      jq '.CreateAccountStatus.AccountId'
  )

  if [[ $prod_account_id != null ]]; then
    break;
  else
    sleep 4.19
  fi
done

printf "moving the rookie accounts into the engineering ou..\n"

aws organizations move-account \
  --account-id=$test_account_id \
  --source-parent-id=$root_ou_id \
  --destination-parent-id=$engineering_ou_id

aws organizations move-account \
  --account-id=$prod_account_id \
  --source-parent-id=$root_ou_id \
  --destination-parent-id=$engineering_ou_id

printf "aws account ids\ntest: $test_account_id\nprod: $prod_account_id\n"