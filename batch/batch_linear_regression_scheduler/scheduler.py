"""
Schedule batch linear regression.
"""
import argparse
import os
import time
from typing import Optional

import boto3
from botocore.exceptions import ClientError

import common
from common import ConfigManager, message_sns, slack_hook_msg
import send_task_to_kinesis

CUSTOMERS = os.environ['CUSTOMERS']

DB_NAME_SSM = os.environ['DB_NAME_SSM']
DB_USER_SSM = os.environ['DB_USER_SSM']
BATCH_STATUS_TABLE = os.environ['BATCH_STATUS_TABLE']

BATCH_PROCESSOR_KINESIS_INPUT_SSM = os.environ['BATCH_PROCESSOR_KINESIS_INPUT_SSM']
RESULT_WRITER_KINESIS_INPUT_SSM = os.environ['RESULT_WRITER_KINESIS_INPUT_SSM']

BATCH_PROCESSOR_COUNT = os.environ['BATCH_PROCESSOR_COUNT']
RESULT_WRITER_COUNT = os.environ['RESULT_WRITER_COUNT']

# Retrieve from env var populated by task definition valueFrom SSM (itself populated by automation). Examples:
# ECS_CLUSTER: 'data-gpu'
# BATCH_ECS_SERVICE: 'linear-regression-batch'
# WRITER_ECS_SERVICE: 'linear-regression-batch-result-writer'
# AUTO_SCALING_GROUP: 'linear-regression-batch-asg'
ECS_CLUSTER = os.environ['TARGET_ECS_CLUSTER']
BATCH_ECS_SERVICE = os.environ['TARGET_BATCH_ECS_SERVICE']
WRITER_ECS_SERVICE = os.environ['TARGET_WRITER_ECS_SERVICE']
AUTO_SCALING_GROUP = os.environ['TARGET_AUTO_SCALING_GROUP']

MAX_NO_CHANGE_COUNT = int(os.environ.get('MAX_NO_CHANGE_COUNT', 100))


def init_db_and_tables(table_name: str):
    print("Starting DB init")
    cnx = common.create_db_conn_with_iam_auth_no_db()
    print("Starting DB init")

    # create database
    with cnx.cursor() as c:
        q = 'CREATE DATABASE IF NOT EXISTS {}'.format(os.environ['DB_DB'])
        c.execute(q)
        cnx.commit()

    # create table
    with cnx.cursor() as c:
        c.execute('USE {}'.format(os.environ['DB_DB']))

        q = "SHOW TABLES LIKE '{}';".format(table_name)
        c.execute(q)
        existed = [r for r in c]
        if len(existed) == 0:
            # table not existed, create one
            c.execute(common.STATUS_TABLE_SCHEMA.format(table_name))
            cnx.commit()
            print("table didn't exist, created")
    print("Completed DB init")


def create_kinesis_stream(kinesis_client, name: str, shards: int, wait_until_exists=True):
    """
    Creates a stream.

    :param shards: Count of shards. Usually it is the same as
    :param kinesis_client:
    :param name: The name of the stream.
    :param wait_until_exists: When True, waits until the service reports that
                              the stream exists, then queries for its metadata.
    """
    try:
        kinesis_client.create_stream(StreamName=name, ShardCount=shards)
        print("Created stream {}.".format(name))
        if wait_until_exists:
            print("Waiting until exists.")
            stream_exists_waiter = kinesis_client.get_waiter('stream_exists')
            stream_exists_waiter.wait(StreamName=name)
    except ClientError:
        print("Couldn't create stream {}.".format(name))
        raise


def delete_kinesis_stream(kinesis_client, name: str):
    """
    Deletes a stream.
    """
    try:
        kinesis_client.delete_stream(StreamName=name)
        stream_deleted_waiter = kinesis_client.get_waiter('stream_not_exists')
        stream_deleted_waiter.wait(StreamName=name)
        print("Deleted stream {}.".format(name))
    except ClientError:
        print("Couldn't delete stream {}.".format(name))
        # raise # don't raise exception as topic may not exist  if first run?


def del_kinesis_topics(topics: list, k):
    for topic in topics:
        try:
            delete_kinesis_stream(k, topic)
        except Exception as e:
            print(e)


def prepare_kinesis(customer: str, k, contacts_file: Optional[str], kinesis_input_stream: str,
                    kinesis_output_stream: str, config: ConfigManager) -> int:
    # delete old kinesis topics
    del_kinesis_topics([kinesis_input_stream, kinesis_output_stream], k)
    print("old Kinesis stream deleted if exist.")

    # prepare kinesis topics
    create_kinesis_stream(k, kinesis_input_stream, int(BATCH_PROCESSOR_COUNT))
    create_kinesis_stream(k, kinesis_output_stream, int(RESULT_WRITER_COUNT))
    print("Kinesis streams ready.")

    # send records to kinesis
    total_records_count = send_task_to_kinesis.process_main(
        customer=customer, status_table=BATCH_STATUS_TABLE,
        kinesis_input=kinesis_input_stream, kinesis_output=kinesis_output_stream,
        contact_file=contacts_file
    )

    print(f'total_records_count: {total_records_count}')

    return total_records_count


def ecs_scale(batch_task_count: int, writer_task_count: int, config: ConfigManager):
    client = boto3.client('ecs')

    print(
        f'Updating ECS service {BATCH_ECS_SERVICE} in cluster {ECS_CLUSTER} with desiredCount {batch_task_count}')

    client.update_service(
        cluster=ECS_CLUSTER,  # config.get_conf('ECS_CLUSTER'),
        service=BATCH_ECS_SERVICE,  # config.get_conf('BATCH_ECS_SERVICE'),
        desiredCount=batch_task_count
    )

    print(
        f'Updating ECS service {WRITER_ECS_SERVICE} in cluster {ECS_CLUSTER} with desiredCount {batch_task_count}')

    client.update_service(
        cluster=ECS_CLUSTER,  # config.get_conf('ECS_CLUSTER'),
        service=WRITER_ECS_SERVICE,  # config.get_conf('WRITER_ECS_SERVICE'),
        desiredCount=writer_task_count
    )


def adjust_auto_scaling_group(desired_count: int, min_count: int, max_count: int, config: ConfigManager):
    client = boto3.client('autoscaling')

    print(
        f'Updating ASG {AUTO_SCALING_GROUP} with MinSize={min_count}, MaxSize={max_count}, DesiredCapacity={desired_count}')

    client.update_auto_scaling_group(
        # config.get_conf('AUTO_SCALING_GROUP'),
        AutoScalingGroupName=AUTO_SCALING_GROUP,
        MinSize=min_count,
        MaxSize=max_count,
        DesiredCapacity=desired_count,
    )

    # Wait until the instances are ready
    time.sleep(60)
    client_ecs = boto3.client('ecs')
    number_container_instances = 0
    while number_container_instances != desired_count:
        print(
            f'Number of container instances {number_container_instances} is != {desired_count}. Wait...')
        time.sleep(5)
        list_container_instances = client_ecs.list_container_instances(
            cluster=ECS_CLUSTER,
            maxResults=100,
            status='ACTIVE'
        )
        print(f'List of container instances: {list_container_instances}')
        number_container_instances = len(
            list_container_instances['containerInstanceArns'])


def report_ecs(config: ConfigManager):
    """
    Have a brief report of task status for batch services.
    """
    client = boto3.client('ecs')

    resp = client.describe_services(
        cluster=ECS_CLUSTER,  # config.get_conf('ECS_CLUSTER'),
        # [config.get_conf('BATCH_ECS_SERVICE'), config.get_conf('WRITER_ECS_SERVICE')]
        services=[BATCH_ECS_SERVICE, WRITER_ECS_SERVICE]
    )

    for status in resp['services']:
        print('{} - {}, desired {}, running {}, pending {}'.format(
            status['serviceName'], status['status'], status['desiredCount'],
            status['runningCount'], status['pendingCount']
        ))


def report(config: ConfigManager, no_change_count: int):
    print('------')
    report_ecs(config)
    print('------')
    report_ssm()
    print('------')
    print('No change count: {}'.format(no_change_count))
    print('++++++END++++++\n')


def wait(kinesis_input: str, kinesis_output: str, config: ConfigManager):
    """
    Wait until most the records have been processed by checking total processed records.

    :param kinesis_output: Input kinesis stream for writer service
    :param kinesis_input: Input kinesis stream for batch processor
    """

    no_change_count = 0
    previous_count = None
    while True:
        cnx = common.create_db_conn_with_iam_auth()
        services = {
            'batch_processor': kinesis_input,
            'writer': kinesis_output
        }
        result = {}
        for service, stream in services.items():
            q = 'select sum(total_records_count), sum(processed_records_count) ' \
                'from {} ' \
                'where stream_name=%(stream)s'.format(BATCH_STATUS_TABLE)
            v = {
                'stream': stream
            }
            with cnx.cursor() as cursor:
                cursor.execute(q, v)
                total = processed = 0
                for row in cursor:
                    total, processed = row
                print('Service {} has {} tasks, and {} processed'.format(
                    service, total, processed))

                result[service] = [total, processed]

        cnx.close()

        all_done = True
        if result['batch_processor'][0] != 0 and result['batch_processor'][0] > result['batch_processor'][1]:
            all_done = False
        if result['batch_processor'][0] > result['writer'][1]:
            all_done = False

        if all_done:
            break

        # if there is no change in count, increase the counter. exit the loop if no change lasts for a while.
        if previous_count is None:
            previous_count = result
        else:
            has_updated = False
            for service in result:
                if previous_count[service] != result[service]:
                    has_updated = True
                    break
            if not has_updated:
                no_change_count += 1
            else:
                no_change_count = 0
                previous_count = result

        if no_change_count >= MAX_NO_CHANGE_COUNT:
            break

        report(config, no_change_count)

        time.sleep(6)

    return processed


def report_ssm():
    ssm = boto3.client('ssm')
    parameters = [
        BATCH_PROCESSOR_KINESIS_INPUT_SSM,
        RESULT_WRITER_KINESIS_INPUT_SSM
    ]
    for p in parameters:
        parameter = ssm.get_parameter(Name=p, WithDecryption=False)
        print('{} -> {}'.format(p, parameter['Parameter']['Value']))


def prepare_parameters(batch_processor_kinesis_input: str, result_writer_kinesis_input: str, config: ConfigManager):
    ssm = boto3.client('ssm')
    value_map = {
        # config.get_conf('BATCH_PROCESSOR_KINESIS_INPUT_SSM'): batch_processor_kinesis_input,
        # config.get_conf('RESULT_WRITER_KINESIS_INPUT_SSM'): result_writer_kinesis_input
        BATCH_PROCESSOR_KINESIS_INPUT_SSM: batch_processor_kinesis_input,
        RESULT_WRITER_KINESIS_INPUT_SSM: result_writer_kinesis_input
    }
    for path, value in value_map.items():
        print(f'Updating SSM parameter with path {path} and value {value}')
        ssm.put_parameter(Name=path, Value=value,
                          Type='String', Overwrite=True)


def get_customers(args) -> list:
    if args.customers is not None:
        print("customer list supplied by command line argument")
        return args.customers.split(',')

    return CUSTOMERS.split(',')
    # return common.get_parameter_from_ssm(SSM_CUSTOMERS, os.environ['AWS_DEFAULT_REGION']).split(',')


def process(args, config_mgr):
    k = common.init_kinesis_client()
    customers = get_customers(args)
    customers = [customer.strip() for customer in customers]
    print(f"List of customers found: {customers}")

    adjust_auto_scaling_group(
        # desired_count=int(config_mgr.get_conf('BATCH_PROCESSOR_COUNT')),
        # min_count=int(config_mgr.get_conf('BATCH_PROCESSOR_COUNT')),
        # max_count=int(config_mgr.get_conf('BATCH_PROCESSOR_COUNT')), config=config_mgr

        desired_count=int(BATCH_PROCESSOR_COUNT),
        min_count=int(BATCH_PROCESSOR_COUNT),
        max_count=int(BATCH_PROCESSOR_COUNT), config=config_mgr
    )

    for customer in customers:
        message_sns('Batch linear regression for {} started...'.format(customer))
        print('Batch linear regression for {} started...'.format(customer))

        kinesis_input_stream = 'batch-linear-regression-input-{}'.format(
            customer)
        kinesis_output_stream = 'batch-linear-regression-output-{}'.format(
            customer)

        total_count = prepare_kinesis(customer, k, args.input_contacts_file,
                                      kinesis_input_stream, kinesis_output_stream, config_mgr)
        print('Batch linear regression started - {}'.format(total_count), customer)
        slack_hook_msg(
            'Batch linear regression started - {}'.format(total_count), customer)

        prepare_parameters(kinesis_input_stream,
                           kinesis_output_stream, config_mgr)
        print('SSM parameters updated.')

        ecs_scale(
            # int(config_mgr.get_conf('BATCH_PROCESSOR_COUNT')),
            # int(config_mgr.get_conf('RESULT_WRITER_COUNT')),
            int(BATCH_PROCESSOR_COUNT),
            int(RESULT_WRITER_COUNT),
            config_mgr
        )

        processed = wait(kinesis_input_stream,
                         kinesis_output_stream, config_mgr)

        ecs_scale(0, 0, config_mgr)

        del_kinesis_topics([kinesis_input_stream, kinesis_output_stream], k)

        message_sns(
            'Batch linear regression for {} finished...'.format(customer))
        slack_hook_msg(
            f'Batch linear regression finished - {processed}/{total_count}', customer)

    adjust_auto_scaling_group(
        desired_count=0, min_count=0, max_count=0, config=config_mgr)


def init_args():
    parser = argparse.ArgumentParser(description="Batch linear regression Tool")
    parser.add_argument(
        "-c", "--customers",
        help="List of customers to search. Separated by comma. E.g. a,b,c",
        required=False
    )
    parser.add_argument("-s", "--s3-conf-file",
                        help="S3 path for the configuration file", required=False)
    parser.add_argument(
        "-i", "--input-contacts-file",
        help="Input file for contacts. If it is specified, the script will use contacts from this file",
        required=False
    )

    return parser.parse_args()


def test():
    k = common.init_kinesis_client()
    customer = 'test'
    config_mgr = ConfigManager('', '')
    kinesis_input_stream = 'batch-linear-regression-input-{}'.format(customer)
    kinesis_output_stream = 'batch-linear-regression-output-{}'.format(customer)

    prepare_kinesis(customer, k, '', kinesis_input_stream,
                    kinesis_output_stream, config_mgr)


if __name__ == '__main__':
    args = init_args()
    # config_mgr = ConfigManager(args.s3_conf_file, SSM_CONF)
    # TODO: remove config_mgr
    config_mgr = ""

    try:
        # init_db_and_tables(config_mgr.get_conf('BATCH_STATUS_TABLE'))
        init_db_and_tables(BATCH_STATUS_TABLE)
        process(args, config_mgr)
    except Exception as e:
        print('Batch linear regression failed {}'.format(str(e)))
        message_sns('Batch linear regression failed {}'.format(str(e)))
    finally:
        ecs_scale(0, 0, config_mgr)
        adjust_auto_scaling_group(
            desired_count=0, min_count=0, max_count=0, config=config_mgr)
