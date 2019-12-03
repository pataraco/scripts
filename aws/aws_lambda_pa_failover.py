#!/usr/bin/env python
"""
    Description:
        Script to be used as an AWS Lamba function to failover from a
        primary Palo Alto server to a hot standby server.

        Using AWS CloudWatch to monitor the Palo Alto servers, when an issue
        is detected, CloudWatch will send a notification to SNS which will
        send a message with the notification to AWS Lambda to run this script.

        This script performs two main functions:
            1. If/When the primary Palo Alto EC2 instance fails, move the EIP
               attachments from the network interfaces of the primary to those
               of the standby Palo Alto instance
            2. Change the routing tables for the DMZ and Internal subnets
               to point to the network interfaces of the standby server

        This script only swaps and re-routes if and when the failed instance
        is the primary server (determined by the instance's Primary tag).

    Usage:
        This script can be used in one of two ways: via AWS Lambda (using the
        handler entry point) and via direct invocation.

        AWS Lambda:
        ----------

        1. AWS Lambda function is subscribed to an AWS SNS topic
        2. AWS CloudWatch alarm monitors the Palo Alto instance status
           and sends an alert to the SNS topic when there is a failure
        3. AWS SNS topic sends notification (containing failure "message") to
           AWS Lambda
        4. AWS Lambda uses the "lambda_handler" function as the entry point
           to this script providing "event" which contains the "message"

        Directly:
        --------

        pa_failover.py [-h] -f FAILED_PA_INSTANCE_ID [-v] [-d] [--dry-run]

        fail over Palo Alto instance from primary to standby

        required arguments:
          -f FAILED_PA_INSTANCE_ID,
          --failed-pa-instance-id FAILED_PA_INSTANCE_ID
                              EC2 Instance ID of failed Palo Alto server

        optional arguments:
          -h, --help          show this help message and exit
          -v, --verbose       turn on verbose output
          -d, --debug         turn on debug output
          --dry-run           do not execute the commands - perform a dry-run

    Requirements:

        The AWS Lambda function or IAM user or EC2 instance must have the
        correct IAM Role/Policy/Credentials to run this script

        In particular, the following services and actions are needed:

            ec2:AssociateAddress
            ec2:CreateTags
            ec2:DescribeInstances
            ec2:DescribeNetworkInterfaces
            ec2:DescribeRouteTables
            ec2:ReplaceRoute

    Overview (Steps performed by script):
        1. Get the failed instance description via instance id (provided by
           the "event" (Lambda) or by the argument given (directly)
        2. Determine if failed instance is the primary PA (Primary tag = true)
        3. If the failed instance is the primary, get the standby instance
           description via tags (Role: Firewall, Primary: false)
        4. Acquire the EIP allocation IDs attached to the primary network
           interfaces
        5. Connect the EIPs to the network interfaces of the standby instance
        6. Update the Primary tags for both instances (true <-> false)
        7. Update the route tables to use the network interfaces of the standby

    Example of an event (dict) passed to the lambda handler:
        (note: "Message" is in JSON format)

        Event: {
          'Records': [
            {
              'EventVersion': '1.0',
              'EventSubscriptionArn': 'arn:aws:sns:us-east-1:448472785679:PA-Failure:02a48004-6777-4712-8df5-f6ed3ab3908c',
              'EventSource': 'aws:sns',
              'Sns': {
                'SignatureVersion': '1',
                'Timestamp': '2018-05-16T04:32:46.972Z',
                'Signature': 'PlMVlRQVapI2mTaokk0HBWUi2nmrwjUXTVnnuvidUHlFLh6lbIFhG7EdBXD8Wxrurz2ZrEcaZGlZTRHypKNEkuGd/D8A3TqrJi41Q5u+lkodQ==',
                'SigningCertUrl': 'https://sns.us-east-1.amazonaws.com/SimpleNotificationService-eaea6120e66ea12e88dcd8bcbddca752.pem',
                'MessageId': '2500982f-6ccc-58fc-a291-cb5ada62a720',
                'Message': '{
                  "AlarmName":"pa-2-status-check",
                  "AlarmDescription":null,
                  "AWSAccountId":"448472785679",
                  "NewStateValue":"ALARM",
                  "NewStateReason":"Threshold Crossed: 1 out of the last 1 datapoints [0.0 (16/05/18 04:31:00)] was greater than or equal to the threshold (0.0) (minimum 1 datapoint for OK -> ALARM transition).",
                  "StateChangeTime":"2018-05-16T04:32:46.932+0000",
                  "Region":"US East (N. Virginia)",
                  "OldStateValue":"OK",
                  "Trigger":{
                    "MetricName":"StatusCheckFailed",
                    "Namespace":"AWS/EC2",
                    "StatisticType":"Statistic",
                    "Statistic":"MINIMUM",
                    "Unit":null,
                    "Dimensions":[
                      {
                        "name":"InstanceId",
                        "value":"i-0eecbfb39c7c62181"
                      }
                    ],
                    "Period":60,
                    "EvaluationPeriods":1,
                    "ComparisonOperator":"GreaterThanOrEqualToThreshold",
                    "Threshold":0.0,
                    "TreatMissingData":"- TreatMissingData: notBreaching",
                    "EvaluateLowSampleCountPercentile":""
                  }
                }',
                'MessageAttributes': {},
                'Type': 'Notification',
                'UnsubscribeUrl': 'https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:448472785679:PA-Failure:02a48004-6777-4712-8df5-f6ed3ab3908c',
                'TopicArn': 'arn:aws:sns:us-east-1:448472785679:PA-Failure',
                'Subject': 'Status Check Alarm: "pa-2-status-check" in US East (N. Virginia)'
              }
            }
          ]
        }

    TODO:
        - think of a TODO (i.e. a way to improve this script)
        - improve documentation
        - look into using boto3.resource
"""

from __future__ import print_function
import argparse
import json
import sys
import boto3
import botocore.exceptions


def lambda_handler(event, context):
    """Handler used by AWS Lambda as an entry point to run this script."""
    print('debug: Script name:', __name__)
    print('debug: Event:', event)
    print('debug: Function name:', context.function_name)
    print('debug: Function version:', context.function_version)
    print('debug: Invoked function ARN:', context.invoked_function_arn)
    print('debug: Log stream name:', context.log_stream_name)
    print('debug: Log group name:', context.log_group_name)
    print('debug: AWS Request ID:', context.aws_request_id)
    print('debug: Memory limits(MB):', context.memory_limit_in_mb)
    # get the SNS json message from event
    action = 'get SNS message from event'
    try:
        message = event['Records'][0]['Sns']['Message']
    except KeyError as e:
        print('debug: exception (KeyError): {e}'.format(**locals()))
        sys.exit('exit: not able to {action}'.format(**locals()))
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        print('debug: able to {action}'.format(**locals()))
    # convert the JSON message to a dict
    action = 'convert the SNS JSON message to a dict'
    try:
        message = json.loads(message)
    except TypeError as e:
        print('debug: exception (TypeError): {e}'.format(**locals()))
        sys.exit('exit: not able to {action}'.format(**locals()))
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        print('debug: able to {action}'.format(**locals()))
    # get the state of the AWS CloudWatch alarm
    new_state = message.get('NewStateValue')
    # only process ALARMs
    action = 'get instance ID from SNS message'
    if new_state == 'ALARM':
        # get the failed EC2 instance ID provided by CloudWatch
        try:
            dimension_name = message['Trigger']['Dimensions'][0]['name']
            if dimension_name == 'InstanceId':
                failed_inst_id = message['Trigger']['Dimensions'][0]['value']
        except KeyError as e:
            print('debug: exception (KeyError): {e}'.format(**locals()))
            sys.exit('exit: not able to {action}'.format(**locals()))
        except Exception as e:
            catch_all_exception_handler(action, e)
        else:
            print('debug: able to {action}'.format(**locals()))
    if failed_inst_id:
        result = main(failed_inst_id)
    else:
        result = 'failed: cannot get failed instance ID from event details'
    print('debug: Time remaining (MS):', context.get_remaining_time_in_millis())
    print(result)
    return result


def boto_no_credentials_error_exception_handler(action, exception):
    """Handles botocore NoCredentialsError exceptions and exits."""
    debug_print(
        'exception (NoCredentialsError): {exception}'.format(**locals()))
    sys.exit(
        'exit: AWS credentials not set:'
        ' not able to {action}'.format(**locals()))


def boto_client_error_exception_handler(
        action, exception, aws_svc_action, **kwargs):
    """Handles botocore ClientError exceptions and exits
       (unless it's a dry run)."""
    error_code = exception.response['Error']['Code']
    eip_alloc_id = kwargs.get('EipAllocationId')
    instance_id = kwargs.get('InstanceId')
    net_int_id = kwargs.get('NetworkInterfaceId')
    private_ip = kwargs.get('PrivateIpAddress')
    resource_id = kwargs.get('ResourceId')
    debug_print(
        'exception (ClientError):'
        ' error code ({error_code}): {exception}'.format(**locals()))
    if error_code == 'AccessDenied':
        sys.exit(
            'exit: permission denied to AWS service:action ({aws_svc_action}):'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'AuthFailure':
        sys.exit(
            'exit: not able to validate AWS credentials:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'DryRunOperation':
        verbose_print('dry-run: not going {action}'.format(**locals()))
    elif error_code == 'InvalidAllocationID.NotFound':
        sys.exit(
            'exit: the allocation id ({eip_alloc_id}) does not exist:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'InvalidClientTokenId':
        sys.exit(
            'exit: invalid AWS credentials:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'InvalidID':
        sys.exit(
            'exit: the EC2 resource ID ({resource_id}) does not exist:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'InvalidInstanceID.Malformed':
        sys.exit(
            'exit: invalid EC2 instance ID ({instance_id}) malformed:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'InvalidInstanceID.NotFound':
        sys.exit(
            'exit: EC2 instance ID ({instance_id}) does not exist:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'InvalidNetworkInterfaceID.NotFound':
        sys.exit(
            'exit: EC2 network interface ID ({net_int_id}) does not exist:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'InvalidParameterValue':
        sys.exit(
            'exit: the IP address ({private_ip}) is not mapped to'
            ' EC2 interface ID ({net_int_id}):'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'RequestExpired':
        sys.exit(
            'exit: temporary AWS credentials expired:'
            ' not able to {action}'.format(**locals()))
    elif error_code == 'UnauthorizedOperation':
        sys.exit(
            'exit: not authorized to perform'
            ' AWS service:action ({aws_svc_action})'
            ' - verify IAM role permission(s):'
            ' not able to {action}'.format(**locals()))
    else:
        sys.exit(
            'exit: exception (ClientError):'
            ' error code ({error_code}): {exception}'
            ' Not able to {action}'.format(**locals()))


def catch_all_exception_handler(action, exception):
    """Handles any catch-all exceptions and exits.
       Typically bad practice to use a "catch-all" execption handler
       but have done some due diligence first. This is used in case
       something was missed and/or not tested for."""
    error_class = exception.__class__
    error_name = exception.__class__.__name__
    debug_print(
        'exception (Catch All):'
        ' error [class ({error_class}) name ({error_name})]:'
        ' {exception}'.format(**locals()))
    sys.exit(
        'exit: error: {exception}: not able to {action}'.format(**locals()))


def create_boto_service_client(service):
    """Create AWS service connection - returns the client."""
    action = 'create boto service client ({service})'.format(**locals())
    verbose_print('attempting to {action}...'.format(**locals()))
    try:
        client = boto3.client(service_name=service)
    except botocore.exceptions.NoRegionError as e:
        debug_print(
            'exception (NoRegionError):'
            ' not able to {action} - exception: {e}'.format(**locals()))
        sys.exit(
            'exit: AWS region not set:'
            ' not able to {action}'.format(**locals()))
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        verbose_print('able to {action}'.format(**locals()))
    return client


def get_eip_allocation_ids(net_int_id):
    """Return any EIP allocation IDs attached to an ENI (as a list)."""
    action = (
        'get any EIP allocation ID(s) of'
        ' network interface ({net_int_id})'.format(**locals()))
    verbose_print('attempting to {action}...'.format(**locals()))
    try:
        describe_network_interfaces_output = (
            ec2_client.describe_network_interfaces(
                NetworkInterfaceIds=[net_int_id]))
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:DescribeNetworkInterfaces',
            NetworkInterfaceId=net_int_id)
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        verbose_print('able to {action}'.format(**locals()))
        debug_print('ec2.describe_network_interfaces output:',
                    describe_network_interfaces_output)
    eip_alloc_ids = []
    network_interfaces = (
        describe_network_interfaces_output.get('NetworkInterfaces'))
    if network_interfaces:
        private_ips = network_interfaces[0].get('PrivateIpAddresses')
        if private_ips:
            for pip in private_ips:
                if 'Association' in pip:
                    if 'AllocationId' in pip['Association']:
                        eip_alloc_ids.append(
                            pip['Association']['AllocationId'])
    else:
        debug_print('no network interfaces found')
        sys.exit('exit: not able to {action}'.format(**locals()))
    return eip_alloc_ids


def attach_eip(eip_alloc_id, net_int_id, priv_ip, dry_run):
    """Attach an EIP to a specific private IP on an network interface."""
    action = (
        'attach EIP ({eip_alloc_id})'
        ' to private IP ({priv_ip})'
        ' on network interface ({net_int_id})'.format(**locals()))
    verbose_print('attempting to {action}...'.format(**locals()))
    try:
        associate_address_output = (
            ec2_client.associate_address(
                AllocationId=eip_alloc_id,
                DryRun=dry_run,
                NetworkInterfaceId=net_int_id,
                PrivateIpAddress=priv_ip))
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:AssociateAddress',
            EipAllocationId=eip_alloc_id,
            NetworkInterfaceId=net_int_id,
            PrivateIpAddress=priv_ip)
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        verbose_print('able to {action}'.format(**locals()))
        debug_print(
            'ec2.associate_address output:'
            ' {associate_address_output}'.format(**locals()))


def move_eips(from_inst, to_inst, dry_run):
    """Moves EIPs from one instance to another."""
    from_inst_id = from_inst.id
    to_inst_id = to_inst.id
    action = (
        'move EIPs from instance ({from_inst_id})'
        ' to instance ({to_inst_id})'.format(**locals()))
    verbose_print('attempting to {action}...'.format(**locals()))
    for ni in from_inst.network_interfaces:
        if ni != 'eth0':
            eip_allocation_ids = get_eip_allocation_ids(
                from_inst.network_interfaces[ni]['eni_id'])
            if eip_allocation_ids:
                to_inst_eni = to_inst.network_interfaces[ni]['eni_id']
                to_inst_pips = to_inst.network_interfaces[ni]['priv_ips']
                if len(eip_allocation_ids) == len(to_inst_pips):
                    eain = 0
                    for eip_alloc_id in eip_allocation_ids:
                        to_inst_pip = to_inst_pips[eain]
                        attach_eip(eip_alloc_id, to_inst_eni, to_inst_pip, dry_run)
                        eain += 1
                else:
                    verbose_print('not able to {action}'.format(**locals()))
                    debug_print(
                        'destination instance ({to_inst_id}) does not have'
                        ' matching number of private IPs on'
                        ' network interface ({to_inst_eni}):'.format(**locals()))
                    sys.exit('exit: not able to {action}'.format(**locals()))


class Ec2Instance(object):
    """Instantiate EC2 Instance objects of an existing EC2 instance
       by either an instance ID or specific tag values. Sets up the following
       attributes:

           id(string): the instance ID (string)
           description (dict): instance description (via 'describe_instances')
           network_interfaces(dict): network interface information
           tags(dict): the instance tags
           is_primary(bool): whether or not the instance is the primary

           from_instance_id(inst_id): instantiate object via instance ID
           from_tags(): instantiate object via tags (Role and Primary)
           update_tag(tag, val): update the value of tag to val."""

    def __init__(self, description):
        """Instantiates an Ec2Instance object"""
        action = 'instantiate an EC2 Instance'

        def is_primary():
            """Return whether or not the instance is the primary Palo Alto."""
            action = 'find out if the PA instance is the primary'
            verbose_print('attempting to {action}...'.format(**locals()))
            instance_id = self.id
            tag = 'Primary'
            tag_values = [
                t['Value'] for t in self.tags
                if t['Key'] == tag]
            if len(tag_values) == 1:
                primary_tag_val = tag_values[0]
                verbose_print('found primary tag value for instance')
                debug_print(
                    'instance id ({instance_id}) \'{tag}\' tag'
                    ' value ({primary_tag_val})'.format(**locals()))
            else:
                verbose_print(
                    'did not find'
                    ' \'{tag}\' tag value for instance'.format(**locals()))
                debug_print(
                    'instance id ({instance_id})'
                    ' \'{tag}\' tag not found'.format(**locals()))
            return bool(primary_tag_val == 'true')

        def get_net_ints(network_interfaces):
            """Returns information about the instance's network interfaces.
               Information returned is a dict containing the
               network interface ID (eni), list of private IPs and subnet ID"""
            action = 'get the instance\'s network interface information'
            verbose_print('attempting to {action}...'.format(**locals()))
            instance_id = self.id
            network_interfaces = [(
                'eth' + str(ni['Attachment']['DeviceIndex']),
                ni['NetworkInterfaceId'],
                [pi['PrivateIpAddress'] for pi in ni['PrivateIpAddresses']],
                ni['SubnetId']) for ni in network_interfaces]
            net_ints = {}
            for ni, ei, pis, si in network_interfaces:
                net_ints[ni] = {'eni_id': ei, 'priv_ips': pis, 'subnet_id': si}
            if net_ints:
                verbose_print('able to {action}'.format(**locals()))
                debug_print(
                    'instance ({instance_id})'
                    ' network interfaces {net_ints}'.format(**locals()))
                return net_ints
            else:
                verbose_print(
                    'did not find network interface info for instance')
                debug_print(
                    'instance ({instance_id}) network interface info'
                    ' not found'.format(**locals()))
            sys.exit('exit: not able to {action}'.format(**locals()))

        self.description = description
        instance_id = description.get('InstanceId')
        if instance_id:
            self.id = instance_id
        tags = description.get('Tags')
        if tags:
            self.tags = tags
        else:
            sys.exit(
                'exit: instance ({instance_id}) does not have any tags:'
                ' not able to {action}'.format(**locals()))
        self.is_primary = is_primary()
        network_interfaces = description.get('NetworkInterfaces')
        if network_interfaces:
            self.network_interfaces = get_net_ints(network_interfaces)
        else:
            sys.exit(
                'exit: instance ({instance_id})'
                ' does not have any network interfaces:'
                ' not able to {action}'.format(**locals()))

    @classmethod
    def from_instance_id(cls, instance_id):
        """Get EC2 instance description using an instance ID."""
        action = (
            'get EC2 instance description'
            ' by instance ID ({instance_id})'.format(**locals()))
        verbose_print('attempting to {action}...'.format(**locals()))
        try:
            describe_instances_output = (
                ec2_client.describe_instances(InstanceIds=[instance_id]))
        except botocore.exceptions.NoCredentialsError as e:
            boto_no_credentials_error_exception_handler(action, e)
        except botocore.exceptions.ClientError as e:
            boto_client_error_exception_handler(
                action, e, 'ec2:DescribeInstances', InstanceId=instance_id)
        except Exception as e:
            catch_all_exception_handler(action, e)
        else:
            verbose_print('able to {action}'.format(**locals()))
            debug_print(
                'ec2.describe_instances output:'
                ' {describe_instances_output}'.format(**locals()))
        reservations = describe_instances_output.get('Reservations')
        if reservations:
            reservation = reservations[0]
            instances = reservation.get('Instances')
            if instances:
                description = instances[0]
                debug_print(
                    'instance description:'
                    ' {description}'.format(**locals()))
                return cls(description)
        else:
            verbose_print('did not find any instances')
            debug_print(
                'no instances found'
                ' with instance id ({instance_id})'.format(**locals()))
        sys.exit('exit: not able to {action}'.format(**locals()))

    @classmethod
    def from_tags(cls):
        """Get EC2 Instance description using
           Tags (Role:Firewall) and (Primary:false)."""
        action = (
            'get instance description'
            ' by Tags (Role:Firewall) and (Primary:false)'.format(**locals()))
        verbose_print('attempting to {action}...'.format(**locals()))
        try:
            describe_instances_output = ec2_client.describe_instances(
                Filters=[
                    {'Name': 'tag:Role', 'Values':['Firewall']},
                    {'Name': 'tag:Primary', 'Values':['false']}
                ])
        except botocore.exceptions.NoCredentialsError as e:
            boto_no_credentials_error_exception_handler(action, e)
        except botocore.exceptions.ClientError as e:
            boto_client_error_exception_handler(
                action, e, 'ec2:DescribeInstances')
        except Exception as e:
            catch_all_exception_handler(action, e)
        else:
            verbose_print('able to {action}'.format(**locals()))
            debug_print(
                'ec2.describe_instances output:'
                ' {describe_instances_output}'.format(**locals()))
        reservations = describe_instances_output.get('Reservations')
        if reservations:
            no_of_instances_found = len(reservations)
            debug_print(
                'number of instances found:'
                ' {no_of_instances_found}'.format(**locals()))
            if no_of_instances_found == 1:
                verbose_print('found just one matching instance')
                reservation = reservations[0]
                instances = reservation.get('Instances')
                if instances:
                    if len(instances) == 1:
                        description = instances[0]
                        debug_print(
                            'instance description:'
                            ' {description}'.format(**locals()))
                        return cls(description)
            elif no_of_instances_found > 1:
                verbose_print('found multiple matching instances')
                instance_ids = []
                for r in reservations:
                    instances = r.get('Instances')
                    if instances:
                        if len(instances) == 1:
                            instance = instances[0]
                            instance_id = instance.get('InstanceId')
                            if instance_id:
                                instance_ids.append(instance_id)
                debug_print(
                    'instances found: {instance_ids}'.format(**locals()))
        else:
            verbose_print('did not find any instances')
            debug_print(
                'no instances found'
                ' with tag ({tag}) val ({val})'.format(**locals()))
        sys.exit('exit: not able to {action}'.format(**locals()))

    def update_tag(self, tag, val, dry_run):
        """update the value of tag to a new value."""
        instance_id = self.id
        action = (
            'update tag ({tag}) to value ({val})'
            ' for instance ({instance_id})'.format(**locals()))
        verbose_print('attempting to {action}...'.format(**locals()))
        try:
            create_tags_output = (
                ec2_client.create_tags(
                    DryRun=dry_run,
                    Resources=[self.id],
                    Tags=[{'Key': tag, 'Value': val}]))
        except botocore.exceptions.NoCredentialsError as e:
            boto_no_credentials_error_exception_handler(action, e)
        except botocore.exceptions.ClientError as e:
            boto_client_error_exception_handler(
                action, e, 'ec2:CreateTags', ResourceId=self.id)
        except Exception as e:
            catch_all_exception_handler(action, e)
        else:
            verbose_print('able to {action}'.format(**locals()))
            debug_print(
                'ec2.create_tags output:'
                ' {create_tags_output}'.format(**locals()))


def get_route_id(subnet_id):
    """Get EC2 route table ID using subnet ID."""
    action = (
        'get route table ID associated'
        ' with subnet ID ({subnet_id})'.format(**locals()))
    verbose_print('attempting to {action}...'.format(**locals()))
    try:
        describe_route_tables_output = ec2_client.describe_route_tables(
            Filters=[{'Name': 'association.subnet-id', 'Values':[subnet_id]}])
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:DescribeRouteTables')
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        verbose_print('able to {action}'.format(**locals()))
        debug_print(
            'ec2.describe_route_tables output:'
            ' {describe_route_tables_output}'.format(**locals()))
    route_tables = describe_route_tables_output.get('RouteTables')
    if route_tables:
        route_table_id = route_tables[0].get('RouteTableId')
        if route_table_id:
            verbose_print(
                'found route table ({route_table_id})'.format(**locals()))
            debug_print(
                'route table ({route_table_id})'
                ' associated with subnet ({subnet_id})'.format(**locals()))
            return route_table_id
    verbose_print('did not find any route tables')
    debug_print(
        'no route tables found'
        ' associated with subnet ({subnet_id})'.format(**locals()))
    sys.exit('exit: not able to {action}'.format(**locals()))


def replace_route(route_table_id, network_interface_id, dry_run):
    """Route the default destination (0.0.0.0/0) to the specified
       network interface ID."""
    action = (
        'route external destination (0.0.0.0/0) to'
        ' network interface ({network_interface_id})'
        ' for route table ID ({route_table_id})'.format(**locals()))
    verbose_print('attempting to {action}...'.format(**locals()))
    try:
        replace_route_output = (
            ec2_client.replace_route(
                RouteTableId=route_table_id,
                DestinationCidrBlock='0.0.0.0/0',
                DryRun=dry_run,
                NetworkInterfaceId=network_interface_id))
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:ReplaceRoute',
            NetworkInterfaceId=network_interface_id)
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        verbose_print('able to {action}'.format(**locals()))
        debug_print(
            'ec2.replace_route output:'
            ' {replace_route_output}'.format(**locals()))


def main(failed_pa_instance_id, verbose=True, debug=True, dry_run=False):
    """Main function to perform all steps highlighted in description.
       Returns a result string describing actual action taken."""
    global ec2_client
    global verbose_print
    global debug_print
    # set up verbose printing
    if verbose:
        def verbose_print(*args):
            print('info:', *args)
        verbose_print('verbosity turned on')
    else:
        verbose_print = lambda *a: None    # do nothing function
    # set up debug printing
    if debug:
        def debug_print(*args):
            print('debug:', *args)
        debug_print('debug turned on')
    else:
        debug_print = lambda *a: None    # do nothing function
    if dry_run:
        verbose_print('performing dry-run')
    # connect to the AWS EC2 service
    ec2_client = create_boto_service_client('ec2')
    # get the failed instance description (using instance id)
    failed_instance = Ec2Instance.from_instance_id(failed_pa_instance_id)
    if failed_instance.is_primary:
        # get the standby instance information (using Primary tag == false)
        standby_instance = Ec2Instance.from_tags()
        if standby_instance:
            verbose_print(
                'failing over:'
                ' failed instance is the primary & found the standby')
            # move eips over
            move_eips(failed_instance, standby_instance, dry_run)
            # swap Primary tags
            failed_instance.update_tag('Primary', 'false', dry_run)
            standby_instance.update_tag('Primary', 'true', dry_run)
            # update the route tables
            for ni in 'eth2', 'eth3':
                for subnet_id in (
                        failed_instance.network_interfaces[ni]['subnet_id'],
                        standby_instance.network_interfaces[ni]['subnet_id']):
                    route_table_id = get_route_id(subnet_id)
                    replace_route(
                        route_table_id,
                        standby_instance.network_interfaces[ni]['eni_id'],
                        dry_run)
            if dry_run:
                return (
                    'dry-run: did not failover primary Palo Alto'
                    ' from ({0}) to ({1})'.format(
                        failed_instance.id, standby_instance.id))
            else:
                return (
                    'failed over primary Palo Alto'
                    ' from ({0}) to ({1})'.format(
                        failed_instance.id, standby_instance.id))
        else:
            return 'can not fail over: unknown state'
    else:
        return 'not failing over: failed instance is not the primary'


if __name__ == '__main__':
    """Checks if this script has be run directly (e.g. via command line),
       if so verifies usage and calls main()"""

    # parse command line arguments
    parser_description = 'fail over Palo Alto instance from primary to standby'
    parser = argparse.ArgumentParser(description=parser_description)
    parser.add_argument(
        '-f', '--failed-pa-instance-id',
        required=True,
        help='EC2 Instance ID of the failed Palo Alto server')
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='turn on verbose output')
    parser.add_argument(
        '-d', '--debug',
        action='store_true',
        help='turn on debug output')
    parser.add_argument(
        '--dry-run',
        action='store_true',
        default=False,
        help='do not execute the commands - perform a dry-run')
    args = parser.parse_args()
    # set up vars
    failed_inst_id = args.failed_pa_instance_id
    verbose = args.verbose
    debug = args.debug
    dry_run = args.dry_run
    # call main() and grab/print the result
    result = main(failed_inst_id, verbose, debug, dry_run)
    print(result)
