import os
import json

DEPLOY_ENV = os.environ.get('DEPLOY_ENV')
with open(f'environments-customers/{DEPLOY_ENV}/environments_definition.json', 'r') as f:
    deployments = json.load(f)

BUILDKITE_MESSAGE = os.environ.get('BUILDKITE_MESSAGE')
BUILDKITE_COMMIT = os.environ.get('BUILDKITE_COMMIT')
BUILDKITE_BRANCH = os.environ.get('BUILDKITE_BRANCH')

PACKAGE_DOCKER_LABEL = os.environ.get('PACKAGE_DOCKER_LABEL')

DEPLOY_ACCOUNT_NAME = deployments[DEPLOY_ENV]['accountName']
DEPLOY_ACCOUNT_ID = deployments[DEPLOY_ENV]['accountId']

pipeline = []

for region, regionValue in deployments[DEPLOY_ENV]['regions'].items():
    buildkiteDeploymentQueue = regionValue['buildKiteDeploymentQueue']

    for site in regionValue['sites']:
        if site['batchlinearRegressionCustomers']:
            pipeline.append({
                'label': f':rocket: Deploy to account {DEPLOY_ACCOUNT_NAME} - region {region} - site {site["siteId"]}',
                'trigger': f'{os.environ.get("SERVICE_NAME")}-deploy',
                'depends_on': ['docker_push', 'terraform_static_analysis', f'block_deploy_{DEPLOY_ENV}'],
                'build': {
                    'message': BUILDKITE_MESSAGE,
                    'commit': BUILDKITE_COMMIT,
                    'branch': BUILDKITE_BRANCH,
                    'env': {
                        'DEPLOY_ACCOUNT_NAME': DEPLOY_ACCOUNT_NAME,
                        'DEPLOY_ENV': DEPLOY_ENV,
                        'DEPLOY_REGION': region,
                        'DEPLOY_ID': site['siteId'],
                        'DEPLOY_NAME': site['mleProjectName'],
                        'BUILDKITE_PLUGIN_S3_SECRETS_BUCKET_PREFIX': 'http_server',
                        'PACKAGE_DOCKER_LABEL': PACKAGE_DOCKER_LABEL,
                        'BUILDKITE_DEPLOYMENT_QUEUE': buildkiteDeploymentQueue,
                        'DEPLOY_ACCOUNT_ID': DEPLOY_ACCOUNT_ID,
                        'DEPLOY_BATCH_LINEAR_REGRESSION_CUSTOMERS': site['batchlinearRegressionCustomers'],
                        'DEPLOY_BATCH_PROCESSOR_COUNT': site['batchlinearRegressionProcessorCount'],
                        'DEPLOY_RESULT_WRITER_COUNT': site['batchlinearRegressionResultWriterCount']
                    },
                },
            })

print(json.dumps(pipeline))
