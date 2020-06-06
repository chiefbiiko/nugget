#!/usr/bin/env bash

set -o pipefail

function help {
  printf "warning: run this once only for dns initialization!

note:
  - make sure the prod account owns the prod domain
    - TODO(chiefbiiko): transfer the prod domain to the fresh prod account
  - the test account should be an unconfigured rookie
  
usage: %s [-h, --help]
  --prod_domain PROD_DOMAIN
  --test_domain TEST_DOMAIN
  --test_account_id TEST_ACCOUNT_ID
  --prod_account_id PROD_ACCOUNT_ID" \
  "$(basename "$0")"
}

while [[ $# -ne 0 ]]; do case $1 in
  --prod_domain) prod_domain=$2; shift 2;;
  --test_domain) test_domain=$2; shift 2;;
  --test_account_id) test_account_id=$2; shift 2;;
  --prod_account_id) prod_account_id=$2; shift 2;;
  -h|--help) help; exit 0;;
esac; done

if [[ -z "$prod_domain" ]] || [[ -z "$test_domain" ]] || 
   [[ -z "$test_account_id" ]] || [[ -z "$prod_account_id" ]]; then
  help; exit 0;
fi

set -u

exit

# TODO: printf all the time!

# TODO: auth with test account & create a hosted zone for the test account and record its NS servers TODO
aws sts assume-role \
  --role-arn="arn:aws:iam::$test_account_id:role/OrganizationAccountAccessRole" \
  --role-session-name=test_dns_oaar

# TODO: capture ns servers from HostedZone output structure
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html
test_hosted_zone="$(
  aws route53 create-hosted-zone \
    --name="$test_domain." \
    --caller-reference="test_$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
)"

test_ns="$(jq -r '.DelegationSet.NameServers[]' <<< $test_hosted_zone)"

# TODO: auth with prod account & create a hosted zone (if not existing) for the prod account
aws sts assume-role \
  --role-arn="arn:aws:iam::$prod_account_id:role/OrganizationAccountAccessRole" \
  --role-session-name=prod_dns_oaar

prod_hosted_zones=$(
  aws route53 list-hosted-zones \
    --max-items=1 \
    --output=json \
    --query='.HostedZones'
)

prod_hosted_zones_count="$(jq 'length' <<< "$prod_hosted_zones")"

if [[ "$prod_hosted_zone_count" == "0" ]]; then
  prod_hosted_zone_id="$(
    aws route53 create-hosted-zone \
      --name="$prod_domain." \
      --caller-reference="prod_$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
      --output=json \
      --query='.HostedZone.Id'
  )"
else
  # TODO
  # find hosted zone with "$prod_domain."
  prod_hosted_zone="$(jq ".HostedZones[] | select(.Name == '$prod_domain.')" <<< "$prod_hosted_zones")"
  #if ffound  extract its id
  
  prod_hosted_zone_id=""
fi

# TODO: create a NS record with key "test.$domain" and as value the four NS
#   servers of the fresh test hosted zone in the prod hosted zone
RECORDS='{
  "Comment": "NS record pointing to the test subdomain",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "%s",
        "Type": "NS",
        "TTL": 172800,
        "ResourceRecords": [
          {
            "Value": "%s"
          }
        ]
      }
    }
  ]
}'

aws route53 change-resource-record-sets \
  --hosted-zone-id="$prod_hosted_zone_id" \
  --change-batch="$(printf "$RECORDS" "$test_domain" "$test_ns")"

# TODO: print hosted zone ids