#!/usr/bin/env bash

# TODO: think about whether setting the test hosted zone up here or in cfn

set -Eeuo pipefail

DOMAIN=$1

cat <<EOF
warning: this is intended to be a one-time-run script!
make sure the (test.)$DOMAIN@gmail.com email adresses exist
before running this script
EOF

exit 1

aws organizations create-organization --feature-set=ALL

root_id=$(aws organizations list-roots --max-items=1 | jq '.Roots[].Id')

aws organizations create-organizational-unit --parent-id=$root_id --name=Engineering

aws organizations create-account \
  --email="test.$DOMAIN@gmail.com" \
  --account-name=test \
  --role-name=OrganizationAccountAccessRole

aws organizations create-account \
  --email="$DOMAIN@gmail.com" \
  --account-name=prod \
  --role-name=OrganizationAccountAccessRole