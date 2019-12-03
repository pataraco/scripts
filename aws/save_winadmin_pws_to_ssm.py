#!/usr/bin/python
"""
    Description:
        Adds decrypted Windows Administrator passwords for Windows EC2 Instances
        to SSM parameter store.

        The list of instances to get and store the passwords for are selected
        by a tag key=value pair.

        If the instance doesn't have a Windows Administrator password, then
        nothing is done.

    Usage:
        save_winadmin_pws_to_ssm.py [-h] [-d] [--dry-run] -p PRIVATE_KEY_FILE
                                   -s SSM_PARAMETER -t TAG [-v]

        get windows instance administrator passwords for specific key=val tags and save
to SSM parameter store

optional arguments:
  -h, --help            show this help message and exit
  -d, --debug           turn on debug output
  --dry-run             do not execute the commands - perform a dry-run
  -p PRIVATE_KEY_FILE, --private-key-file PRIVATE_KEY_FILE
                        path/name to private key file used to launch the EC2
                        instance.used to decrypt the windows administrater
                        password
  -s SSM_PARAMETER, --ssm-parameter SSM_PARAMETER
                        SSM parameter key prefix to use to store the
                        password.the "Name" tag of the instance will be
                        appended(i.e. /ssm/param-key/path/INSTANCE_NAME)
  -t TAG, --tag TAG     key=val tag designating which EC2 instances to save
                        thepasswords of
  -v, --verbose         turn on verbose output


    Usage:
        save_winadmin_pws_to_ssm.py [-h] -p PRIVATE_KEY_FILE [-v] [-d] [--dry-run]

        get windows instance administrator passwords for specific key=val
        tags and save to SSM parameter store

        required arguments:
          -p PRIVATE_KEY_FILE,
          --private-key-file PRIVATE_KEY_FILE
                              EC2 Instance ID of failed Palo Alto server

        optional arguments:
          -h, --help          show this help message and exit
          -v, --verbose       turn on verbose output
          -d, --debug         turn on debug output
          --dry-run           do not execute the commands - perform a dry-run

    Requirements:

        The user running this program must have the
        correct IAM Role/Policy/Credentials to run this script and have access
        to the following services and be able to run the actions:

            ec2:DescribeInstances
            ec2:GetPasswordData
            ssm:PutParameter

# usage: put-ssm-params "ASP Web GIS" /asp-web-gis ~/.ssh/onica-ext-migration.pem

"""

from argparse import ArgumentParser
import base64
import logging
import sys
import boto3
import rsa
import botocore.exceptions

logging.basicConfig()
LOGGER = logging.getLogger(__name__)


def boto_no_region_error_exception_handler(action, exception):
    """Handles botocore NoRegionError exceptions and exits."""
    LOGGER.debug('exception (NoRegionError): %s', exception)
    sys.exit('exit: AWS region not set: not able to {}'.format(action))


def boto_no_credentials_error_exception_handler(action, exception):
    """Handles botocore NoCredentialsError exceptions and exits."""
    LOGGER.debug('exception (NoCredentialsError): %s', exception)
    sys.exit('exit: AWS credentials not set: not able to {}'.format(action))


def boto_client_error_exception_handler(
        action, exception, aws_svc_action, **kwargs):
    """Handles botocore ClientError exceptions and exits
       (unless it's a dry run)."""
    error_code = exception.response['Error']['Code']
    instance_id = kwargs.get('InstanceId')
    LOGGER.debug('exception (ClientError):'
                 ' error code (%s): %s', error_code, exception)
    if error_code == 'AccessDenied':
        sys.exit('exit: permission denied to AWS service:action ({}):'
                 ' not able to {}'.format(aws_svc_action, action))
    elif error_code == 'AuthFailure':
        sys.exit('exit: not able to validate AWS credentials:'
                 ' not able to {}'.format(action))
    elif error_code == 'DryRunOperation':
        LOGGER.info('dry-run: not going {action}'.format(**locals()))
    elif error_code == 'InvalidClientTokenId':
        sys.exit('exit: invalid AWS credentials:'
                 ' not able to {}'.format(action))
    elif error_code == 'InvalidInstanceID.Malformed':
        sys.exit('exit: invalid EC2 instance ID ({instance_id}) malformed:'
                 ' not able to {}'.format(action))
    elif error_code == 'InvalidInstanceID.NotFound':
        sys.exit('exit: EC2 instance ID ({instance_id}) does not exist:'
                 ' not able to {}'.format(action))
    elif error_code == 'RequestExpired':
        sys.exit('exit: temporary AWS credentials expired:'
                 ' not able to {}'.format(action))
    elif error_code == 'UnauthorizedOperation':
        sys.exit('exit: not authorized to perform AWS service:action ({})'
                 ' - verify IAM role permission(s):'
                 ' not able to {}'.format(aws_svc_action, action))
    else:
        sys.exit('exit: exception (ClientError):'
                 ' error code ({error_code}): {exception}'
                 ' not able to {action}'.format(**locals()))


def catch_all_exception_handler(action, exception):
    """Handles any catch-all exceptions and exits.
       Typically bad practice to use a "catch-all" execption handler
       but have done some due diligence first. This is used in case
       something was missed and/or not tested for."""
    error_class = exception.__class__
    error_name = exception.__class__.__name__
    LOGGER.debug('exception (Catch All): error [class (%s) name (%s)]:'
                 ' %s', error_class, error_name, exception)
    sys.exit('exit: error: {}: not able to {}'.format(exception, action))


def create_boto_service_client(service):
    """Create AWS service connection - returns the client."""
    action = 'create boto service client ({})'.format(service)
    LOGGER.info('attempting to %s...', action)
    try:
        client = boto3.client(service_name=service)
    except botocore.exceptions.NoRegionError as e:
        boto_no_region_error_exception_handler(action, e)
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        LOGGER.info('able to %s', action)
        LOGGER.debug('%s client: %s', service, client)
    return client


def get_list_of_servers(tag_key_val):
    """Get list of instances with tag (key:value) pair to get passwords of."""
    logger = logging.getLogger('get_list')
    tag_key, tag_val = tag_key_val.split('=')

    ec2_client = create_boto_service_client('ec2')

    action = ('get list of instances with'
              ' tag key ({tag_key}) val ({tag_val})'.format(**locals()))
    LOGGER.info('attempting to %s...', action)
    try:
        describe_instances_output = ec2_client.describe_instances(
            Filters=[{'Name': 'instance-state-name', 'Values': ['running']},
                     {'Name': 'tag:'+tag_key, 'Values': ['*'+tag_val+'*']}])
    except botocore.exceptions.NoCredentialsError as e:
        boto_no_credentials_error_exception_handler(action, e)
    except botocore.exceptions.ClientError as e:
        boto_client_error_exception_handler(action, e, 'ec2:DescribeInstances')
    except Exception as e:
        catch_all_exception_handler(action, e)
    else:
        LOGGER.info('able to %s...', action)
        LOGGER.debug('ec2.describe_instances output: %s',
                     describe_instances_output)
    reservations = describe_instances_output['Reservations']
    if reservations:
        LOGGER.debug('found %s instances', len(reservations))
        instances = {}
        for reservation in reservations:
            instance = reservation['Instances'][0]
            instance_id = instance['InstanceId']
            tags = instance['Tags']
            instance_name = [t['Value'] for t in tags if t['Key'] == 'Name'][0]
            instances[instance_id] = instance_name
    else:
        LOGGER.debug('did not find any matching instances')
        return reservations
    return instances


def add_win_admin_pws_to_ssm(dry_run, priv_key_file, ssm_param, tag_key_val):
    """Add Windows Administrator passwords to SSM parameter store."""
    instances = get_list_of_servers(tag_key_val)
    if instances:
        ec2_client = create_boto_service_client('ec2')
        ssm_client = create_boto_service_client('ssm')

        for instance_id, instance_name in instances.iteritems():
            # echo "getting windows admin passwords: "
            action = ('get password data for'
                      ' {instance_name} ({instance_id})'.format(**locals()))
            LOGGER.info('attempting to %s', action)
            try:
                get_password_data_output = ec2_client.get_password_data(
                    InstanceId=instance_id)
                encrypted_pw = base64.b64decode(
                    get_password_data_output['PasswordData'].strip())
                LOGGER.debug('encrypted password: %s', encrypted_pw)
            except botocore.exceptions.NoCredentialsError as e:
                boto_no_credentials_error_exception_handler(action, e)
            except botocore.exceptions.ClientError as e:
                boto_client_error_exception_handler(
                    action, e, 'ec2:GetPasswordData')
            except Exception as e:
                catch_all_exception_handler(action, e)
            else:
                LOGGER.info('able to %s', action)
                LOGGER.debug('ec2.get_password_data output: %s',
                             get_password_data_output)

            if encrypted_pw:
                ssm_param_name = ssm_param + '/' + instance_name

                action = ('decrypt the password')
                LOGGER.info('attempting to %s', action)
                with open(priv_key_file, 'r') as pkf:
                    private_key = rsa.PrivateKey.load_pkcs1(pkf.read())
                decrypted_pw = rsa.decrypt(encrypted_pw, private_key)
                LOGGER.info('able to %s', action)
                LOGGER.debug('decrypted password: %s', decrypted_pw)

                action = ('save admin password ({decrypted_pw}) of'
                          ' {instance_name} ({instance_id})'
                          ' in ssm key: {ssm_param_name}'.format(**locals()))
                LOGGER.info('attempting to %s', action)
                if dry_run:
                    print('dry-run: {instance_id},'
                          ' ssm param name: {ssm_param_name},'
                          ' password: [{decrypted_pw}]'.format(**locals()))
                else:
                    try:
                        put_parameter_output = ssm_client.put_parameter(
                            Description='Windows Administrator password',
                            Name=ssm_param_name,
                            Overwrite=True,
                            Type='SecureString',
                            Value=decrypted_pw)
                        version = put_parameter_output['Version']
                    except botocore.exceptions.NoCredentialsError as e:
                        boto_no_credentials_error_exception_handler(action, e)
                    except botocore.exceptions.ClientError as e:
                        boto_client_error_exception_handler(
                            action, e, 'ec2:GetPasswordData')
                    except Exception as e:
                        catch_all_exception_handler(action, e)
                    else:
                        LOGGER.info('able to %s', action)
                        LOGGER.debug('ec2.put_parameter output: %s',
                                     put_parameter_output)
                        print('saved: {instance_id},'
                              ' ssm param name: {ssm_param_name},'
                              ' password: [{decrypted_pw}],'
                              ' version: {version}'.format(**locals()))
            else:
                print('no password found for:'
                      ' {instance_name} ({instance_id})'.format(**locals()))


def parse_arguments():
    """parses command line arguements"""
    # parse command line arguments
    parser = ArgumentParser(
        description='get windows instance administrator passwords for specific'
                    ' key=val tags and save to SSM parameter store')
    parser.add_argument(
        '-d', '--debug',
        action='store_true',
        default=False,
        help='turn on debug output')
    parser.add_argument(
        '--dry-run',
        action='store_true',
        default=False,
        help='do not execute the commands - perform a dry-run')
    parser.add_argument(
        '-p', '--private-key-file',
        required=True,
        help='path/name to private key file used to launch the EC2 instance.'
             ' used to decrypt the windows administrater password')
    parser.add_argument(
        '-s', '--ssm-parameter',
        required=True,
        help='SSM parameter key prefix to use to store the password.'
             ' the "Name" tag of the instance will be appended'
             ' (i.e. /ssm/param-key/path/INSTANCE_NAME)')
    parser.add_argument(
        '-t', '--tag',
        required=True,
        help='key=val tag designating which EC2 instances to save the'
             ' passwords of')
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        default=False,
        help='turn on verbose output')
    args = parser.parse_args()
    # set up vars
    if args.debug:
        LOGGER.setLevel(logging.DEBUG)
    if args.verbose:
        LOGGER.setLevel(logging.INFO)
    return args


def main():
    """main module"""
    args = parse_arguments()
    add_win_admin_pws_to_ssm(
        args.dry_run,
        args.private_key_file,
        args.ssm_parameter,
        args.tag)


if __name__ == '__main__':
    main()
