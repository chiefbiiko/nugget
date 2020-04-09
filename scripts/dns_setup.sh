#!/usr/bin/env bash

set -uo pipefail

DOMAIN=$1
TEST_ACCOUNT_ID=$2
PROD_ACCOUNT_ID=$3

cat <<EOF
warning: $0 is intended to be run once for initialization only!
note: make sure the prod account $PROD_ACCOUNT_ID owns the domain $DOMAIN
EOF

# TODO: prep all zone and domain names carefully (prefix, trailiing dot, etc.)
test_zone_name=TODO
prod_zone_name=TODO
test_domain_name=TODO
prod_domain_name=TODO

# TODO: create a hosted zone for the test account and record its NS servers
# TODO: create a hosted zone for the prod account
# TODO: create a NS record with key "test.$domain" and as value the four NS
#   servers of the fresh test hosted zone in the prod hosted zone