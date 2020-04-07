# nugget infra

everything related to nugget's infrastructure

## stacks

### `depl`

continuous deployment setup providing one user to maintain all nugget
stacks. this template's outputs provide the aws credentials that are
prerequisites for performing the stack updates. Make sure to manually
deploy this stack to the test and prod account, then set the github secrets
AWS_ACCESS_KEY_ID_PROD, AWS_SECRET_ACCESS_KEY_PROD, AWS_ACCESS_KEY_ID_TEST,
AWS_SECRET_ACCESS_KEY_TEST given the corresponding stack outputs.

### `site`

a website distribution stack using a route53 domain

### `mail`

a bike-shed domain mail stack as a proxy between route53 and gmail
