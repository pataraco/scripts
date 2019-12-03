#!/usr/bin/env python
#
# Description:
#     Script to delete an AWS IAM user
#
#     Deletes the specified IAM user and all of their objects.
#
#     When done, the user will not belong to any groups, have any access keys,
#     signing certificates, attached policies, in-line policies,
#     SSH public keys or service specific credentials.
#
# Usage:
#     Show usage with: aws_delete_user.py -h
#
# Requirements:
#     - Must have AWS credentials to get/delete/remove IAM resources
#     - AWS environment variables must be set (profile or keys)
#
# TODO:
#     - enable the '--dry-run' option
#     - add capability to specify more than one user at a time
#     - figure out how to reduce repeated/common code
#
# Steps:
#     - first make sure that the user exists
#     - check for and remove user from any/all groups
#     - check for and remove any/all access keys
#     - check for and remove any/all signing certificates
#     - check for and remove any/all attached policies
#     - check for and remove any/all in-line policies
#     - check for and remove any/all SSH public keys
#     - check for and remove any/all service specific credentials
#     - delete any MFA devices
#     - delete the user's login profile (password)
#     - finally delete the user

import argparse
import boto3
import botocore.exceptions
import sys

def create_boto_service_client(service):
# create AWS service connection - return client
    action = "to create boto service client ({0})".format(service)
    verbose_print("attempting {0}...".format(action))
    try:
        client = boto3.client(service_name=service)
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    verbose_print("able {0}".format(action))
    return client

def get_user(iam_client, user_name):
    action = "to get user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        get_user_output = iam_client.get_user(UserName=user_name)
        debug_print("iam.get_user output: {0}".format(get_user_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        elif e_code == 'InvalidClientTokenId':
            sys.exit("invalid credentials ({0}): not able {1}".format(e_code, action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    print("verified user ({0}) exists...".format(user_name))

def verify_deletion(user_name):
    print("WARNING: going to delete user ({0}) and all of their related objects".format(user_name))
    print("         including access keys, MFA devices, SSH keys, signing certificates")
    user_choice = raw_input("enter user's name ({0}) to continue: ".format(user_name))
    if user_choice != user_name:
        debug_print("correct user name ({0}) not entered - exiting".format(user_name))
        sys.exit("okay - NOT deleting user ({0})".format(user_name))
    else:
        debug_print("correct user name ({0}) entered - continuing".format(user_name))
        verbose_print("okay - deleting user ({0})".format(user_name))
 
def remove_user_from_groups(iam_client, user_name):
    main_action = "to remove user ({0}) from any and all groups".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list groups for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_groups_for_user_output = iam_client.list_groups_for_user(UserName=user_name)
        debug_print("iam.list_groups_for_user output: {0}".format(list_groups_for_user_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        groups = []
        for group in list_groups_for_user_output['Groups']:
            group_name = group['GroupName']
            groups.append(group_name)
            action = "to remove user ({0}) from group ({1})".format(user_name, group_name)
            verbose_print("attempting {0}...".format(action))
            remove_user_from_group_output = iam_client.remove_user_from_group(UserName=user_name, GroupName=group_name)
            debug_print("iam.remove_user_from_group output: {0}".format(remove_user_from_group_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or group does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(groups) > 0:
        print("removed user ({0}) from group(s) {1}...".format(user_name, groups))
    else:
        print("user ({0}) does not belong to any groups...".format(user_name))

def remove_access_keys_from_user(iam_client, user_name):
    main_action = "to remove access keys from user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list access keys for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_access_keys_output = iam_client.list_access_keys(UserName=user_name)
        debug_print("iam.list_access_keys output: {0}".format(list_access_keys_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        access_key_ids = []
        for access_key in list_access_keys_output['AccessKeyMetadata']:
            access_key_id = access_key['AccessKeyId']
            access_key_ids.append(access_key_id)
            action = "to remove access key ({0}) from user ({1})".format(access_key_id, user_name)
            verbose_print("attempting {0}...".format(action))
            delete_access_key_output = iam_client.delete_access_key(UserName=user_name, AccessKeyId=access_key_id)
            debug_print("iam.delete_access_key output: {0}".format(delete_access_key_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or access key does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(access_key_ids) > 0:
        print("removed access key(s) {0} from user ({1})...".format(access_key_ids, user_name))
    else:
        print("user ({0}) does not have any access keys...".format(user_name))

def remove_signing_certs_from_user(iam_client, user_name):
    main_action = "to remove signing certificates from user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list signing certificates for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_signing_certificates_output = iam_client.list_signing_certificates(UserName=user_name)
        debug_print("iam.list_signing_certificates output: {0}".format(list_signing_certificates_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        certificate_ids = []
        for certificate in list_signing_certificates_output['Certificates']:
            certificate_id = certificate['CertificateId']
            certificate_ids.append(certificate_id)
            action = "to remove signing certificate ({0}) from user ({1})".format(certificate_id, user_name)
            verbose_print("attempting {0}...".format(action))
            delete_signing_certificate_output = iam_client.delete_signing_certificate(UserName=user_name, CertificateId=certificate_id)
            debug_print("iam.delete_signing_certificate output: {0}".format(delete_signing_certificate_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or signing certificate does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(certificate_ids) > 0:
        print("removed signing certificate(s) {0} from user ({1})...".format(certificate_ids, user_name))
    else:
        print("user ({0}) does not have any signing certificates...".format(user_name))

def detach_policies_from_user(iam_client, user_name):
    main_action = "to detach policies from user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list attached policies for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_attached_user_policies_output = iam_client.list_attached_user_policies(UserName=user_name)
        debug_print("iam.list_attached_user_policies output: {0}".format(list_attached_user_policies_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        policy_names = []
        for policy in list_attached_user_policies_output['AttachedPolicies']:
            policy_arn = policy['PolicyArn']
            policy_name = policy['PolicyArn'].split('/')[1]
            policy_names.append(policy_name)
            action = "to detach policy ({0}) from user ({1})".format(policy_name, user_name)
            verbose_print("attempting {0}...".format(action))
            detach_user_policy_output = iam_client.detach_user_policy(UserName=user_name, PolicyArn=policy_arn)
            debug_print("iam.detach_user_policy output: {0}".format(detach_user_policy_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or policy does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(policy_names) > 0:
        print("detached policies {0} from user ({1})...".format(policy_names, user_name))
    else:
        print("user ({0}) does not have any attached policies...".format(user_name))

def delete_inline_policies_from_user(iam_client, user_name):
    main_action = "to delete inline policies from user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list inline policies for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_user_policies_output = iam_client.list_user_policies(UserName=user_name)
        debug_print("iam.list_user_policies output: {0}".format(list_user_policies_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        policy_names = []
        for policy_name in list_user_policies_output['PolicyNames']:
            policy_names.append(policy_name)
            action = "to delete inline policy ({0}) from user ({1})".format(policy_name, user_name)
            verbose_print("attempting {0}...".format(action))
            delete_user_policy_output = iam_client.delete_user_policy(UserName=user_name, PolicyName=policy_name)
            debug_print("iam.delete_user_policy output: {0}".format(delete_user_policy_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or policy does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(policy_names) > 0:
        print("deleted inline policies {0} from user ({1})...".format(policy_names, user_name))
    else:
        print("user ({0}) does not have any inline policies...".format(user_name))

def delete_ssh_keys_from_user(iam_client, user_name):
    main_action = "to remove SSH public keys from user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list SSH public keys for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_ssh_public_keys_output = iam_client.list_ssh_public_keys(UserName=user_name)
        debug_print("iam.list_ssh_public_keys output: {0}".format(list_ssh_public_keys_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        ssh_public_key_ids = []
        for ssh_public_key in list_ssh_public_keys_output['SSHPublicKeys']:
            ssh_public_key_id = ssh_public_key['SSHPublicKeyId']
            ssh_public_key_ids.append(ssh_public_key_id)
            action = "to remove SSH public key ({0}) from user ({1})".format(ssh_public_key_id, user_name)
            verbose_print("attempting {0}...".format(action))
            delete_ssh_public_key_output = iam_client.delete_ssh_public_key(UserName=user_name, SSHPublicKeyId=ssh_public_key_id)
            debug_print("iam.delete_ssh_public_key output: {0}".format(delete_ssh_public_key_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or SSH public key does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(ssh_public_key_ids) > 0:
        print("removed SSH public key(s) {0} from user ({1})...".format(ssh_public_key_ids, user_name))
    else:
        print("user ({0}) does not have any SSH public keys...".format(user_name))

def delete_service_specific_creds_from_user(iam_client, user_name):
    main_action = "to remove service specific credentials from user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list service specific credentials for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_service_specific_credentials_output = iam_client.list_service_specific_credentials(UserName=user_name)
        debug_print("iam.list_service_specific_credentials output: {0}".format(list_service_specific_credentials_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        service_specific_credentials_ids = []
        for service_specific_credential in list_service_specific_credentials_output['ServiceSpecificCredentials']:
            service_specific_credential_id = service_specific_credential['ServiceSpecificCredentialId']
            service_specific_credentials_ids.append(service_specific_credential_id)
            action = "to remove service specific credential ({0}) from user ({1})".format(service_specific_credential_id, user_name)
            verbose_print("attempting {0}...".format(action))
            delete_service_specific_credential_output = iam_client.delete_service_specific_credential(UserName=user_name, ServiceSpecificCredentialId=service_specific_credential_id)
            debug_print("iam.delete_service_specific_credential output: {0}".format(delete_service_specific_credential_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or service specific credential does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(service_specific_credentials_ids) > 0:
        print("removed service specific credential(s) {0} from user ({1})...".format(service_specific_credentials_ids, user_name))
    else:
        print("user ({0}) does not have any service specific credentials...".format(user_name))

def delete_mfa_devices(iam_client, user_name):
    main_action = "to delete user's ({0}) MFA device".format(user_name)
    verbose_print("attempting {0}...".format(main_action))
    action = "to list user's ({0}) MFA device".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_mfa_devices_output = iam_client.list_mfa_devices(UserName=user_name)
        debug_print("iam.list_mfa_devices output: {0}".format(list_mfa_devices_output))
        verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        mfa_devices = []
        for mfa in list_mfa_devices_output['MFADevices']:
            serial_number = mfa['SerialNumber']
            mfa_devices.append(serial_number)
            action = "to deactive user's ({0}) MFA device ({1})".format(user_name, serial_number)
            verbose_print("attempting {0}...".format(action))
            deactivate_mfa_device_output = iam_client.deactivate_mfa_device(UserName=user_name, SerialNumber=serial_number)
            debug_print("iam.deactivate_mfa_device output: {0}".format(deactivate_mfa_device_output))
            verbose_print("able {0}".format(action))
            action = "to delete user's ({0}) MFA device ({1})".format(user_name, serial_number)
            verbose_print("attempting {0}...".format(action))
            delete_virtual_mfa_device_output = iam_client.delete_virtual_mfa_device(SerialNumber=serial_number)
            debug_print("iam.delete_virtual_mfa_device output: {0}".format(delete_virtual_mfa_device_output))
            verbose_print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user or policy does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    if len(mfa_devices) > 0:
        print("deleted MFA device(s) {0} from user ({1})...".format(mfa_devices, user_name))
    else:
        print("user ({0}) does not have any MFA devices...".format(user_name))

def delete_login_profile(iam_client, user_name):
    action = "to delete user's ({0}) login profile".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        delete_login_profile_output = iam_client.delete_login_profile(UserName=user_name)
        debug_print("iam.delete_login_profile output: {0}".format(delete_login_profile_output))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            if "Cannot find Login Profile".upper() in e.response['Error']['Message'].upper():
                verbose_print("does not exist: not able {0}".format(action))
                print("user ({0}) does not have a login profile...".format(user_name))
                return
            else:
                sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    verbose_print("able {0}...".format(action))
    print("deleted login profile from user ({0})...".format(user_name))

def delete_user(iam_client, user_name):
    action = "to delete user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        delete_user_output = iam_client.delete_user(UserName=user_name)
        debug_print("iam.delete_user output: {0}".format(delete_user_output))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    verbose_print("able {0}...".format(action))
    print("deleted user ({0})...".format(user_name))

def main():
    global verbose_print
    global debug_print
    # parse command line arguments
    parser_description = 'delete an AWS IAM user and all of their objects'
    parser = argparse.ArgumentParser(description=parser_description)
    parser.add_argument(
        '-u', '--user-name',
        required=True,
        help='AWS IAM console user ID of user being deleted')
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
        help='do NOT execute the commands - perform a dry-run')
 
    args = parser.parse_args()

    # set up debug printing
    debug = args.debug
    if debug:
        def debug_print(*args):
            print "debug:",
            for arg in args:
                print arg,
            print
        debug_print('debug turned on')
    else:
        debug_print = lambda *a: None	# do nothing function

    # set up verbose printing
    verbose = args.verbose
    if verbose:
        def verbose_print(*args):
            print "info:",
            for arg in args:
                print arg,
            print
        verbose_print('verbosity turned on')
    else:
        verbose_print = lambda *a: None	# do nothing function

    # set up vars
    user_name = args.user_name
    dry_run = args.dry_run
    if dry_run:
        sys.exit("sorry: option '--dry-run' is not supported yet")
        verbose_print('performing dry-run')

    # connect to the AWS IAM service
    iam_client = create_boto_service_client('iam')

    # make sure user exists first
    get_user(iam_client, user_name)
    # verify/confirm desire to proceed
    verify_deletion(user_name)
    # check for and remove user from any/all groups
    remove_user_from_groups(iam_client, user_name)
    # check for and remove any/all access keys
    remove_access_keys_from_user(iam_client, user_name)
    # check for and remove any/all signing certificates
    remove_signing_certs_from_user(iam_client, user_name)
    # check for and remove any/all attached policies
    detach_policies_from_user(iam_client, user_name)
    # check for and remove any/all in-line policies
    delete_inline_policies_from_user(iam_client, user_name)
    # check for and remove any/all SSH public keys
    delete_ssh_keys_from_user(iam_client, user_name)
    # check for and remove any/all service specific credentials
    delete_service_specific_creds_from_user(iam_client, user_name)
    # delete any MFA devices
    delete_mfa_devices(iam_client, user_name)
    # delete the user's login profile
    delete_login_profile(iam_client, user_name)
    # finally delete the user
    delete_user(iam_client, user_name)

if __name__ == '__main__':
    main()
