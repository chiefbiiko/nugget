# nugget infra

everything related to nugget's infrastructure

## todo

* complete dns setup bash script
* recheck how to add a spf record to the domains

## stacks

### `custom-resources`

these custom resources are dependencies of the `mail` and `site` stacks:

* [`cfn-certificate-provider`](https://github.com/binxio/cfn-certificate-provider)

* [`cfn-secret-provider`](https://github.com/binxio/cfn-secret-provider)

* [`cfn-ses-provider`](https://github.com/binxio/cfn-ses-provider)

all of these are provided by [`binx.io`](https://github.com/binxio) and included as `git` submodules.

**NOTE** make sure to update the submodules from time to time.

### `depl`

continuous deployment setup providing one user to maintain all nugget
stacks.

this template's outputs provide the aws credentials that are
prerequisites for performing the stack updates.

make sure to initially deploy this stack to the test and prod account, then set
the github secrets `AWS_ACCESS_KEY_ID_PROD`, `AWS_SECRET_ACCESS_KEY_PROD`,
`AWS_ACCESS_KEY_ID_TEST`, `AWS_SECRET_ACCESS_KEY_TEST` given the corresponding
stack outputs.

### `site`

a website distribution stack using a route53 domain.

the `test` and `prod` aws accounts exhibit identical `site` stacks.

### `mail`

a bike-shed domain mail stack as a proxy between route53 and gmail.

**TODO** the `test` and `prod` aws accounts **shall** exhibit identical `mail` stacks.

### cd

launching deployments from github actions with the test branch installing to the aws test account and the master branch installing to the aws prod account.

### misc docs

* https://binx.io/blog/2019/11/14/how-to-deploy-aws-ses-domain-identities-dkim-records-using-cloudformation/

* https://binx.io/blog/2018/03/17/deploying-aws-ses-access-key-and-smtp-password-using-aws-cloudformation/

* http://www.daniloaz.com/en/use-gmail-with-your-own-domain-for-free-thanks-to-amazon-ses-lambda/
