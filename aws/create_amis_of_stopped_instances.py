#!/usr/bin/env python
"""
    Description:
        Script to be used to create AWS AMI images of stopped EC2 instances

    Usage:
        create_amis_of_stopped_instaces.py [-h] [--dry-run]

        create AWS AMIs of stopped EC2 instances

        optional arguments:
          -h, --help          show this help message and exit
          --dry-run           do not execute the commands - perform a dry-run

    Requirements:

        The user of this script must have the AWS environment configured and
        correct IAM Role/Policy/Credentials to run this script

        In particular, the following services and actions are needed:

            ec2:DescribeInstances
            ec2:CreateImage
            ec2:CreateTags

    Overview (Steps performed by script):
        1. Get the list of stopped EC2 instances
        2. Loop through the list
        3. Grab the name of the instance
        4. Generate a default AMI name and description from the name
        5. Display instance name, ID, image name and description
        6. Ask user if they want to proceed with the image creation
        7. Give user option to change either the image name
           or description if not
        8. Create the image if the user agrees

    TODO:
        - Add capability to modify AMI name and description on the fly
          on any particular instance
"""

from __future__ import print_function
import argparse
import sys
import boto3
import botocore.exceptions
from time import strftime


def boto_no_credentials_error_exception_handler(action, exception):
    """Handles botocore NoCredentialsError exceptions and exits."""
    print(
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
    print(
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
        print('dry-run: not going {action}'.format(**locals()))
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
    print(
        'exception (Catch All):'
        ' error [class ({error_class}) name ({error_name})]:'
        ' {exception}'.format(**locals()))
    sys.exit(
        'exit: error: {exception}: not able to {action}'.format(**locals()))


def create_boto_service_client(service):
    """Create AWS service connection - returns the client."""
    action = 'create boto service client ({service})'.format(**locals())
    print('attempting to {action}...'.format(**locals()))
    try:
        client = boto3.client(service_name=service)
    except botocore.exceptions.NoRegionError as e:
        print(
            'exception (NoRegionError):'
            ' not able to {action} - exception: {e}'.format(**locals()))
        sys.exit(
            'exit: AWS region not set:'
            ' not able to {action}'.format(**locals()))
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        print('able to {action}'.format(**locals()))
    return client


def get_list_of_stopped_instances():
    """Get list of stopped EC2 instances."""
    action = 'get list of stopped EC2 instances'
    print('attempting to {action}...'.format(**locals()))
    try:
        describe_instances_output = ec2_client.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values':['stopped']}])
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:DescribeInstances')
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        print('able to {action}'.format(**locals()))
    reservations = describe_instances_output.get('Reservations')
    if reservations:
        no_of_instances_found = len(reservations)
        print(
            'number of instances found:'
            ' {no_of_instances_found}'.format(**locals()))
        instances = {}
        for reservation in reservations:
            instance_id = reservation['Instances'][0]['InstanceId']
            instance_tags = reservation['Instances'][0]['Tags']
            name_tags = [
                t['Value'] for t in instance_tags
                if t['Key'] == 'Name'
            ]
            instance_name = name_tags[0]
            instances[instance_id] = instance_name
        return instances
    else:
        print('did not find any stopped instances')
        return None

def create_image(inst_id, ami_name, ami_desc, dry_run):
    """Create ann AMI of specified instance with given name and description."""
    action = 'create an AMI of instance {inst_id}'.format(**locals())
    print('attempting to {action}...'.format(**locals()))
    try:
        create_image_output = ec2_client.create_image(
            Description=ami_desc,
            DryRun=dry_run,
            InstanceId=inst_id,
            Name=ami_name,
        )
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:CreateImage')
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        # print(create_image_output)
        image_id = create_image_output.get('ImageId')
        print(
            'able to {action}. AMI ID created: {image_id}'.format(**locals()))
    return image_id

def tag_image(ami_name, ami_id, dry_run):
    """Tag the AMI image with the provided name."""
    action = 'tag the AMI ({ami_id}) with name ({ami_name})'.format(**locals())
    print('attempting to {action}...'.format(**locals()))
    try:
        create_tags_output = ec2_client.create_tags(
            DryRun=dry_run,
            Resources=[ami_id],
            Tags=[{'Key': 'Name', 'Value': ami_name}])
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(
            action, e, 'ec2:CreateTags')
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        print('able to {action}'.format(**locals()))


def main(dry_run):
    """Main function to perform all steps highlighted in description."""
    global ec2_client
    # connect to the AWS EC2 service
    ec2_client = create_boto_service_client('ec2')
    # get the list (dict: instance_id:instance_name) of stopped instances
    stopped_instances = get_list_of_stopped_instances()
    for inst_id, inst_name in stopped_instances.iteritems():
        print(
            'working on instance'
            ' name ({inst_name}) ID ({inst_id})'.format(**locals()))
        time_stamp = strftime('%d%b%Y-%Hh%Mm')
        if inst_name:
            ami_name = 'backup-{inst_name}-{time_stamp}'.format(**locals())
            ami_desc = 'backup copy of {inst_name}'.format(**locals())
        else:
            ami_name = 'backup-{inst_id}-{time_stamp}'.format(**locals())
            ami_desc = 'backup copy of {inst_id}'.format(**locals())
        # print(
        #     'demo: aws ec2 create-image'
        #     ' --instance-id {inst_id}'
        #     ' --name "{ami_name}"'
        #     ' --description "{ami_desc}"'.format(**locals()))
        print('preparing to create the following backup image:')
        print(' EC2 Instance (ID): {inst_name} ({inst_id})'.format(**locals()))
        print(' AMI Name:          {ami_name}'.format(**locals()))
        print(' AMI Description:   {ami_desc}'.format(**locals()))
        print
        response = raw_input('Do you wish to proceed (y/n)? ').upper()
        if response == 'Y':
            print('OK, creating AMI')
            ami_id = create_image(inst_id, ami_name, ami_desc, dry_run)
            tag_image(ami_name, ami_id, dry_run)
        else:
            print('OK, NOT creating AMI')

if __name__ == '__main__':
    """Checks if this script has be run directly (e.g. via command line),
       if so verifies usage and calls main()"""

    # parse command line arguments
    parser_description = 'create AWS AMIs of stopped EC2 instances'
    parser = argparse.ArgumentParser(description=parser_description)
    parser.add_argument(
        '--dry-run',
        action='store_true',
        default=False,
        help='do not execute the commands - perform a dry-run')
    args = parser.parse_args()
    # set up vars
    dry_run = args.dry_run
    # call main() and grab/print the result
    main(dry_run)
