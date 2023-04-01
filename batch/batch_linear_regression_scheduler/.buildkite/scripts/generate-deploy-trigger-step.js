const fs = require('fs');
const DEPLOY_ENV = process.env.DEPLOY_ENV

var deployments = JSON.parse(fs.readFileSync(`environments-customers/${DEPLOY_ENV}/environments_definition.json`, 'utf8'));

const BUILDKITE_MESSAGE = process.env.BUILDKITE_MESSAGE
const BUILDKITE_COMMIT = process.env.BUILDKITE_COMMIT
const BUILDKITE_BRANCH = process.env.BUILDKITE_BRANCH


const PACKAGE_DOCKER_LABEL = process.env.PACKAGE_DOCKER_LABEL

const DEPLOY_ACCOUNT_NAME = deployments[DEPLOY_ENV].accountName
const DEPLOY_ACCOUNT_ID = deployments[DEPLOY_ENV].accountId

const pipeline = []

for (const [region, regionValue] of Object.entries(deployments[DEPLOY_ENV].regions)) {

  buildkiteDeploymentQueue = regionValue.buildKiteDeploymentQueue

  for (site of regionValue.sites){

    // only deploy if enabled for at least one customer
    if(site.batchSkillExtractionCustomers){

      pipeline.push({
        label: `:rocket: Deploy to account ${DEPLOY_ACCOUNT_NAME} - region ${region} - site ${site.siteId}`,
        trigger: `${process.env.SERVICE_NAME}-deploy`,
        depends_on: [`docker_push`, `terraform_static_analysis`, `block_deploy_${DEPLOY_ENV}`],
        build: {
          message: BUILDKITE_MESSAGE,
          commit: BUILDKITE_COMMIT,
          branch: BUILDKITE_BRANCH,
          env: {
            DEPLOY_ACCOUNT_NAME: DEPLOY_ACCOUNT_NAME,
            DEPLOY_ENV: DEPLOY_ENV,
            DEPLOY_REGION: region,
            DEPLOY_ID: site.siteId,
            DEPLOY_NAME: site.brainName,
            BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX: "d61_skill_http_server",
            PACKAGE_DOCKER_LABEL: PACKAGE_DOCKER_LABEL,
            BUILDKITE_DEPLOYMENT_QUEUE: buildkiteDeploymentQueue,
            DEPLOY_ACCOUNT_ID: DEPLOY_ACCOUNT_ID,
            DEPLOY_BATCH_LINEAR_REGRESSION_CUSTOMERS: site.batchSkillExtractionCustomers,
            DEPLOY_BATCH_PROCESSOR_COUNT: site.batchSkillExtractionProcessorCount,
            DEPLOY_RESULT_WRITER_COUNT: site.batchSkillExtractionResultWriterCount
          },
        },
      },
      )
    }
  }

}

console.log(JSON.stringify(pipeline))
