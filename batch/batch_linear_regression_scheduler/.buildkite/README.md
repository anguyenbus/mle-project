# Pipeline structure

`pipeline.yml -> generate-deploy-trigger-step.js -> pipeline-deploy.yaml -> generate-ecs-deploy-step.js`

Some components need to be deployed as multiple stack. For instance when the component needs to be deployed for each site.
The deployment part includes many steps itself: terraform scan, plan, apply, ECS deployment, etc
To keep the main pipeline readable in Buildkite UI, we separate out the deployument into a subpipeline called by the first one.

`<component-name>` pipeline makes many calls to `<component-name>-deploy` pipeline. Calling for each site and for each AWS account (Dev, staging, prod)
This way the CI/CD pipeline is not too busy in the buildkite UI.
It also allows calling the deploy pipeline directly if needed. This could be useful for rollback or for a separate process like onboarding a new site (in case the site definition is in a separate it repo or configuration management tool).

## pipeline
CI/CD overall pipeline. Does the build, unit testing, artifact scanning, etc. Delegates the deployment to deployment pipeline

## pipeline-migration
new AWS account structure. Called by the main CI/CD pipeline. (to be cleaned up post migration)
## pipeline-deploy
Used to handle the deployment part https://buildkite.com/anguyenbus/go-deploy

Different env var can be used to deploy to a different site or AWS account or region.
This pipeline can also be called directly if required, rather than from the CI/CD pipeline.

Example of env var to pass to this pipeline if triggered directly:

```
BUILDKITE_DEPLOYMENT_QUEUE="development-us-east-1"
BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX="http_server"
DEPLOY_ACCOUNT_ID="012345678901"
DEPLOY_ACCOUNT_NAME="development"
DEPLOY_BATCH_PROCESSOR_COUNT="1"
DEPLOY_BATCH_SKILLS_EXTRACTION_CUSTOMERS="lendlease"
DEPLOY_ID="001"
DEPLOY_NAME="dev-nva-001"
DEPLOY_ENV="dev"
DEPLOY_REGION="us-east-1"
DEPLOY_RESULT_WRITER_COUNT="1"
PACKAGE_DOCKER_LABEL="build-164"
```


staging ap-southeast-2
```
BUILDKITE_DEPLOYMENT_QUEUE="staging-ap-southeast-2"
BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX="http_server"
DEPLOY_ACCOUNT_ID="199082409103"
DEPLOY_ACCOUNT_NAME="staging"
DEPLOY_ENV="stage"
DEPLOY_REGION="ap-southeast-2"
DEPLOY_ID="004"
PACKAGE_DOCKER_LABEL="build-113"
DEPLOY_NAME="stage-syd-004"
DEPLOY_BATCH_SKILLS_EXTRACTION_CUSTOMERS="nswdcs"
DEPLOY_BATCH_PROCESSOR_COUNT="8"
DEPLOY_RESULT_WRITER_COUNT="2"
```

prod ap-southeast-2
```
BUILDKITE_DEPLOYMENT_QUEUE="production-ap-southeast-2"
BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX="http_server"
DEPLOY_ACCOUNT_ID="515003738239"
DEPLOY_ACCOUNT_NAME="production"
DEPLOY_ENV="prod"
DEPLOY_REGION="ap-southeast-2"
DEPLOY_ID="004"
PACKAGE_DOCKER_LABEL="build-113"
DEPLOY_NAME="prod-syd-004"
DEPLOY_BATCH_SKILLS_EXTRACTION_CUSTOMERS="nswdcs"
DEPLOY_BATCH_PROCESSOR_COUNT="8"
DEPLOY_RESULT_WRITER_COUNT="2"
```


`BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX` -> required as the Git repo name is different from the s3 folder with the keys for buildkite

## generate-deploy-trigger-step.js
This will generate a Buildkite step per site defined in this file (TODO: move site definition in a central location)
The step is a call to the `<component-name>-deploy` pipeline

## generate-ecs-deploy-step.js
We currently use a Buildkite plugin for ECS which needs to have its attributes populated with values.

The terraform output is saved as a JSON file and saved by Buildkite as an artifact.
The artifact is then restored for this step and parsed by the code to generate the ecs deploy plugin step, using the values from the json file.

The values are only known once the terraform step has run, which outputs ARN of AWS resources.
We cannot have the step statically in the yaml.
The plugin does not accept environment variables.
We could improve this and remove the generate ecs deploy step if plugin could handle environment variables (which can be dynamic) or if we used another plugin or mechanism to deploy to ECS

## destroy resources pipeline
https://buildkite.com/anguyenbus/batch-skill-extraction-scheduler-destroy

Environment variables:

staging ap-southeast-2 site 001
```
BUILDKITE_DEPLOYMENT_QUEUE="staging-ap-southeast-2"
BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX="http_server"
DEPLOY_ACCOUNT_ID="199082409103"
DEPLOY_ACCOUNT_NAME="staging"
DEPLOY_BATCH_PROCESSOR_COUNT="1"
DEPLOY_BATCH_SKILLS_EXTRACTION_CUSTOMERS="demo1"
DEPLOY_ID="001"
DEPLOY_NAME="stage-syd-001"
DEPLOY_ENV="stage"
DEPLOY_REGION="ap-southeast-2"
DEPLOY_RESULT_WRITER_COUNT="1"
```
