#!/bin/env python
#
# Description:
#     Quick script to create CodeCommit repo and grant/revoke users access to it
#
#     Create an AWS CodeCommit repo if it doesn't exist, and
#     Add/Remove user access to the AWS CodeCommit repo
#
# Usage:
#     Show usage with: codecommit_admin -h
#
# Requirements:
#     - Must have AWS credentials to get/create CodeCommit and IAM resources
#     - AWS environment variables must be set (profile or keys and region)
#
# TODO:
#     - enable the '--dry-run' option
#     - add function to upload/get public SSH key
#     - minimize/optimize by creating/using more functions
#
# Steps:
#     ADD - Granting Access
#     - create CodeCommit repo (e.g. repo_dev_team) if it doesn't already exist
#     - create IAM group (e.g. CodeCommit_repo_dev_team) if it doesn't already exist
#     - attach IAM inline policy to group
#     - create user if it doesn't already exist
#     - create AWS keys for user if they don't have them
#     - add user to group if they are not already a member
#     - upload public ssh key (if applicable)
#     - email user(s) welcome message and instructions
#     REMOVE - Revoking Access
#     - remove  user from group
#     - email user(s) goodbye message

# POLICY EXAMPLE:
#---------------
#Name: CodeCommitAccessToRepo-repo_dev_team
#{
#	"Version": "2012-10-17",
#	"Statement": [
#		{
#			"Sid": "CodeCommitAccessToRepo",
#			"Effect": "Allow",
#			"NotAction": "codecommit:DeleteRepository",
#			"Resource": "arn:aws:codecommit:us-east-1:1234567890:repo_dev_team"
#		}
#	]
#}

# YAML EXAMPLE
# (used to create repo(s) and grant users' access to them)
# (or to revoke users' access to them)
#---------------
#Name: example.yml
# repos:
#   - name: repo1
#     description: "description1"
#     users:
#       - user: "user1"
#         email: "email1@domain.com"
#       - user: "user2"
#         email: "email2@domain.com"
#   - name: repo2
#     description: "description2"
#     users:
#       - user: "user3"
#         email: "email3@domain.com"
#         sshkey: "file://data/certskeys/example3.pub"

import argparse
import base64
import boto3
import botocore.exceptions
import copy
import difflib
import os
import sys
import yaml

# set some global variables
DEFAULT_REGION = 'us-east-1'          # to create AWS CodeCommit repo
DEFAULT_SES_REGION = 'us-west-2'      # where from email address has been verified
FROM_EMAIL = 'nim-ops@telecomsys.com' # from email address to send notifications
GROUP_NAME_PREFIX = 'CodeCommit_'     # to pre-pend repo name with to create group
IAM_POLICY_TEMPLATE = """\
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "CodeCommitAccessToRepo",
			"Effect": "Allow",
			"NotAction": "codecommit:DeleteRepository",
			"Resource": "arn:aws:codecommit:{region}:{aws_acct}:{repo}"
		}
	]
}
"""
EMAIL_HEADER_TEMPLATE = """\
From: {from}
To: {to}
Subject: {subject}
"""
GRANTED_SUBJECT_TEMPLATE = "AWS CodeCommit access granted to repo: {repo}"
GRANTED_EMAIL_TEMPLATE = """\
Hello,

You have been granted access to the AWS CodeCommit repository: {repo}

{accesskeys}
{sshkeyid}
Please use the folling links for instructions on accessing CodeCommit:

	http://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-https-windows.html
	http://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-https-unixes.html

You can access CodeCommit via SSH by providing a public SSH key and following these instructions:

	http://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-ssh-unixes.html

Skip the parts of the instructions that require you to log into the AWS console because your IAM account has already been created.

If you have any questions or concerns, please let us know.

Thank you,

NIM Ops Team

"""
REVOKED_SUBJECT_TEMPLATE = "AWS CodeCommit access revoked from repo: {repo}"
REVOKED_EMAIL_TEMPLATE = """\
Hello,

Your access has been revoked from the AWS CodeCommit repository: {repo}

If this has been in error or you have any questions or concerns, please let us know.

Thank you,

NIM Ops Team

"""
ACCESS_KEYS_TEMPLATE = """\
Here are your access keys:

	Access Key Id:    {aki}
        Secret Access Key:    {sak}
"""

SSH_KEY_TEMPLATE = """\
To configure SSH access here is your:

        SSH Key Id: {ski}
"""

def create_boto_service_client(service, region):
# create AWS service connection - return client
    action = "to create boto service client ({0})".format(service)
    try:
        client = boto3.client(service_name=service, region_name=region)
        debug_print("created: able {0} using region ({1}) defined".format(action, region))
    except NameError as e:
        debug_print("error: not able {0] using region ({1}) defined".format(action, region))
        sys.exit("error (region): {0}".format(e))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return client

def get_codecommit_repo_info(codecommit_client, repo_name):
# get CodeCommit repo info of an existing repo and return the ARN
    action = "to get CodeCommit repo ({0}) info".format(repo_name)
    verbose_print("attempting {0}...".format(action))
    try:
        get_repository_output = codecommit_client.get_repository(repositoryName=repo_name)
        debug_print("codecommit.get_repository output: {0}".format(get_repository_output))
        print("able {0}".format(action))
        repo_arn = get_repository_output['repositoryMetadata']['Arn']
        debug_print("got info: CodeCommit repo ({0}) arn ({1})".format(repo_name, repo_arn))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'RepositoryDoesNotExistException':
            sys.exit("repo does not exist: not able {0}".format(action))
        elif e_code == 'AccessDeniedException':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return repo_arn

def create_codecommit_repo(codecommit_client, repo_name, repo_desc):
# create the CodeCommit repo if it doesn't already exist and return the ARN
# if it already exits - get it's info
    if not repo_desc:
        repo_desc = "Repo for collaborative development"
    action = "to create CodeCommit repo ({0})".format(repo_name)
    verbose_print("attempting {0}...".format(action))
    try:
        create_repository_output = codecommit_client.create_repository(repositoryName=repo_name, repositoryDescription=repo_desc)
        debug_print("codecommit.create_repository output: {0}".format(create_repository_output))
        print("able {0}: created".format(action))
        repo_arn = create_repository_output['repositoryMetadata']['Arn']
        debug_print("created: CodeCommit repo ({0}) arn ({1})".format(repo_name, repo_arn))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'RepositoryNameExistsException':
            print("not able {0}: already exists".format(action))
            repo_arn = get_codecommit_repo_info(codecommit_client, repo_name)
        elif e_code == 'AccessDeniedException':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return repo_arn

def get_iam_group(iam_client, group_name):
# get IAM group info of an existing group and return the ARN
    action = "to get IAM group ({0}) info".format(group_name)
    verbose_print("attempting {0}...".format(action))
    try:
        get_group_output = iam_client.get_group(GroupName=group_name)
        debug_print("iam.get_group output: {0}".format(get_group_output))
        print("able {0}".format(action))
        group_arn = get_group_output['Group']['Arn']
        debug_print("got info: IAM group ({0}) arn ({1})".format(group_name, group_arn))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("group does not exist: not able {0}".format(action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return group_arn

def create_iam_group(iam_client, group_name):
# create an IAM group if it doesn't already exist and return the ARN
# if it already exits - get it's info
    action = "to create IAM group ({0})".format(group_name)
    verbose_print("attempting {0}...".format(action))
    try:
        create_group_output = iam_client.create_group(GroupName=group_name)
        debug_print("iam.get_create_group output: {0}".format(create_group_output))
        print("able {0}".format(action))
        group_arn = create_group_output['Group']['Arn']
        debug_print("created: IAM group ({0}) arn ({1})".format(group_name, group_arn))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'EntityAlreadyExists':
            print("not able {0}: already exists".format(action))
            group_arn = get_iam_group(iam_client, group_name)
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return group_arn

def attach_iam_policy_to_group(iam_client, group_name, region, aws_acct_number):
# attach IAM inline policy to the group
    policy_name = group_name
    repo_name = group_name.replace(GROUP_NAME_PREFIX, '')
    action = "to attach IAM inline policy ({0}) to group ({1})".format(policy_name, group_name)
    # this doesn't work (KeyError: '\n        "Version"')
    #policy_doc = IAM_POLICY_TEMPLATE.format(region=region, aws_acct=aws_acct_number, repo=repo_name)
    policy_doc = IAM_POLICY_TEMPLATE.replace('{region}:{aws_acct}:{repo}', "{0}:{1}:{2}".format(region, aws_acct_number, repo_name))
    verbose_print("attempting {0}...".format(action))
    try:
        put_group_policy_output = iam_client.put_group_policy(GroupName=group_name, PolicyName=policy_name, PolicyDocument=policy_doc)
        debug_print("iam.put_group_policy output: {0}".format(put_group_policy_output))
        print("able {0}".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))

def get_iam_user(iam_client, user_name):
# get IAM user info of an existing user and return the ARN
    action = "to get IAM user ({0}) info".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        get_user_output = iam_client.get_user(UserName=user_name)
        debug_print("iam.get_user output: {0}".format(get_user_output))
        print("able {0}".format(action))
        user_arn = get_user_output['User']['Arn']
        debug_print("got info: IAM user ({0}) arn ({1})".format(user_name, user_arn))
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
    return user_arn

def create_iam_user(iam_client, user_name):
# create an IAM user if it doesn't already exist and return the ARN
    action = "to create IAM user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        create_user_output = iam_client.create_user(UserName=user_name)
        debug_print("iam.create_user output: {0}".format(create_user_output))
        print("able {0}".format(action))
        user_arn = create_user_output['User']['Arn']
        debug_print("created: IAM user ({0}) arn ({1})".format(user_name, user_arn))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception: (ClientError): not able {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'EntityAlreadyExists':
            print("not able {0}: already exists".format(action))
            user_arn = get_iam_user(iam_client, user_name)
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return user_arn

def create_access_keys(iam_client, user_name):
# create AWS access keys for user if they don't have them
    action = "to create IAM access keys for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        create_access_key_output = iam_client.create_access_key(UserName=user_name)
        debug_print("iam.create_access_key output: {0}".format(create_access_key_output))
        print("able {0}".format(action))
        access_key_id = create_access_key_output['AccessKey']['AccessKeyId']
        secret_access_key = create_access_key_output['AccessKey']['SecretAccessKey']
        debug_print("created: IAM access key id ({0}) secret access key ({1}) for user ({2})".format(access_key_id, secret_access_key, user_name))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception (NoCredentialsError): not able {0} - {1}".format(action, e))
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
    return access_key_id, secret_access_key

def get_user_aws_keys(iam_client, user_name):
# check for and get active AWS access keys for user if they have them
    action = "to get (list) IAM access keys for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_access_keys_output = iam_client.list_access_keys(UserName=user_name)
        debug_print("iam.list_access_keys output: {0}".format(list_access_keys_output))
        access_key_md_list = list_access_keys_output['AccessKeyMetadata']
        print("able {0}".format(action))
        if access_key_md_list:
            debug_print("got info: IAM access keys ({0}) for user ({1})".format(access_key_md_list, user_name))
            access_key_id_list = []
            for access_key_md in access_key_md_list:
                if access_key_md['Status'] == 'Active':
                    access_key_id_list.append(access_key_md['AccessKeyId'])
            if len(access_key_id_list) == 0:
                if len(access_ley_md_list) == 2:
                    sys.exit("can't assign new or use existing set of AWS access keys for user ({0}): user already has 2 and they're both inactive".format(user_name))
                elif len(access_ley_md_list) == 1:
                    debug_print("user ({0}) has 1 inactive set of AWS keys, creating a new set".format(user_name))
                    print("user ({0}) does not have an active set of AWS keys, creating a new set".format(user_name))
                    access_key_id, secret_access_key = create_access_keys(iam_client, user_name)
            elif len(access_key_id_list) > 0:
                print("user ({0}) already has an active set of AWS keys, not creating".format(user_name))
                if len(access_key_id_list) == 1:
                    access_key_id = access_key_id_list[0]
                    secret_access_key = 'use existing'
                elif len(access_key_id_list) == 2:
                    access_key_id = "{0}  or  {1}".format(access_key_id_list[0], access_key_id_list[1])
                    secret_access_key = 'use existing'
                debug_print("got info: IAM access key id(s) ({0}) for user ({1})".format(access_key_id_list, user_name))
        else:
            debug_print("no active sets of AWS keys found for user ({0})".format(user_name))
            print("user ({0}) does not have an active set of AWS keys, creating a new set".format(user_name))
            access_key_id, secret_access_key = create_access_keys(iam_client, user_name)
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
    return access_key_id, secret_access_key

def get_ssh_public_key_id(iam_client, user_name):
# get public SSH key ID for user to configure SSH access to CodeCommit repo - return SSH public key ID
# if they have more than one, just get the first one
    action = "to get SSH public key ID for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        list_ssh_public_keys_output = iam_client.list_ssh_public_keys(UserName=user_name)
        debug_print("iam.list_ssh_public_keys output: {0}".format(list_ssh_public_keys_output))
        verbose_print("able {0}".format(action))
        ssh_public_key_id = list_ssh_public_keys_output['SSHPublicKeys'][0]['SSHPublicKeyId']
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception raised: attempting {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}: ".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception (ClientError): failed {0}".format(action))
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
    return ssh_public_key_id

def upload_user_ssh_key(iam_client, user_name, ssh_key_file_name):
# upload public SSH key for user for SSH access to CodeCommit repo - return SSH public key ID
    action = "to upload SSH public key for user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    try:
        ssh_key_file = open(ssh_key_file_name, 'r')
        ssh_key = ssh_key_file.read()
        debug_print("successfully opened and read SSH key file ({0})".format(ssh_key_file_name))
        debug_print("public SSH key ({0})".format(ssh_key))
        ssh_key_file.close()
    except IOError as e:
        sys.exit("exception(IOError): can't open file ({0}): {1}".format(ssh_key_file_name, e))
    except Exception as e:
        debug_print("exception(Catch All): trying to open file ({0})".format(ssh_key_file_name))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    try:
        upload_ssh_public_key_output = iam_client.upload_ssh_public_key(UserName=user_name, SSHPublicKeyBody=ssh_key)
        debug_print("iam.upload_ssh_public_key output: {0}".format(upload_ssh_public_key_output))
        print("able {0}: uploaded".format(action))
        ssh_public_key_id = upload_ssh_public_key_output['SSHPublicKey']['SSHPublicKeyId']
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception raised: attempting {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}: ".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception (ClientError): failed {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'NoSuchEntity':
            sys.exit("user does not exist: not able {0}".format(action))
        elif e_code == 'DuplicateSSHPublicKey':
            print("not able {0}: already uploaded".format(action))
            ssh_public_key_id = get_ssh_public_key_id(iam_client, user_name)
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))
    return ssh_public_key_id

def add_user_to_group(iam_client, group_name, user_name):
# add user to group to gain access to repo
    action = "to add user ({0}) to group ({1})".format(user_name, group_name)
    verbose_print("attempting {0}...".format(action))
    try:
        add_user_to_group_output = iam_client.add_user_to_group(GroupName=group_name, UserName=user_name)
        debug_print("iam.add_user_to_group output: {0}".format(add_user_to_group_output))
        print("able {0}: added".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception raised: attempting {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}: ".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception (ClientError): failed {0}".format(action))
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

def remove_user_from_group(iam_client, group_name, user_name):
# remove user from group to revoke access to repo
    action = "to remove user ({0}) from group ({1})".format(user_name, group_name)
    verbose_print("attempting {0}...".format(action))
    try:
        remove_user_from_group_output = iam_client.remove_user_from_group(GroupName=group_name, UserName=user_name)
        debug_print("iam.remove_user_from_group output: {0}".format(remove_user_from_group_output))
        print("able {0}: removed".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception raised: attempting {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}: ".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception (ClientError): failed {0}".format(action))
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

def send_granted_email(ses_client, user_name, email, access_key_id, secret_access_key, ssh_key_id, repo_name):
# send a "welcome" email stating access to repo has be granted with instructions on how to access
    action = "to send 'access granted' email to user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    access_keys_msg = ACCESS_KEYS_TEMPLATE.format(aki=access_key_id, sak=secret_access_key)
    if ssh_key_id:
        ssh_key_msg = SSH_KEY_TEMPLATE.format(ski=ssh_key_id)
    else:
        ssh_key_msg = ''
    subject = GRANTED_SUBJECT_TEMPLATE.format(repo=repo_name)
    body = GRANTED_EMAIL_TEMPLATE.format(repo=repo_name, accesskeys=access_keys_msg, sshkeyid=ssh_key_msg)
    try:
        send_email_output = ses_client.send_email(Source=FROM_EMAIL, Destination={'ToAddresses': [email]}, Message={'Subject':{'Data':subject,'Charset':"UTF-8"},'Body':{'Text':{'Data':body,'Charset':"UTF-8"}}})
        debug_print("ses.send_email output: {0}".format(send_email_output))
        print("able {0}: sent".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception raised: attempting {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}: ".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception (ClientError): failed {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'MessageRejected':
            sys.exit("email address ({0}) not verified: not able {1}".format(FROM_EMAIL, action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))

def send_revoked_email(ses_client, user_name, email, repo_name):
# send a "goodbye" email stating access to repo has be revoked
    action = "to send 'access revoked' email to user ({0})".format(user_name)
    verbose_print("attempting {0}...".format(action))
    subject = REVOKED_SUBJECT_TEMPLATE.format(repo=repo_name)
    body = REVOKED_EMAIL_TEMPLATE.format(repo=repo_name)
    try:
        send_email_output = ses_client.send_email(Source=FROM_EMAIL, Destination={'ToAddresses': [email]}, Message={'Subject':{'Data':subject,'Charset':"UTF-8"},'Body':{'Text':{'Data':body,'Charset':"UTF-8"}}})
        debug_print("ses.send_email output: {0}".format(send_email_output))
        print("able {0}: sent".format(action))
    except botocore.exceptions.NoCredentialsError as e:
        debug_print("exception raised: attempting {0} - exception: {1}".format(action, e))
        sys.exit("AWS credentials NOT set: not able {0}: ".format(action))
    except botocore.exceptions.ClientError as e:
        debug_print("exception (ClientError): failed {0}".format(action))
        e_code = e.response['Error']['Code']
        if e_code == 'MessageRejected':
            sys.exit("email address ({0}) not verified: not able {1}".format(FROM_EMAIL, action))
        elif e_code == 'AccessDenied':
            sys.exit("access denied: not able {0}".format(action))
        else:
            debug_print("error: {0}".format(e))
            sys.exit("error code ({0}): not able {1}".format(e_code, action))
    except Exception as e:
        debug_print("exception(Catch All): not able {0}".format(action))
        debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
        sys.exit("error: {0}".format(e))

def grant_access_to_user(codecommit_client, iam_client, ses_client, repo_name, repo_desc, user_name, email, ssh_key, region):
    group_name = GROUP_NAME_PREFIX + repo_name
    # create CodeCommit repo if it doesn't already exist, otherwise get it
    repo_arn = create_codecommit_repo(codecommit_client, repo_name, repo_desc)
    # get the AWS account number from the CodeCommit repo ARN
    aws_acct_number=repo_arn.split(':')[4]
    # create IAM group it doesn't already exist, otherwise get it
    create_iam_group(iam_client, group_name)
    # attach policy to group unless it's already attached or inline
    attach_iam_policy_to_group(iam_client, group_name, region, aws_acct_number)
    # create user if it doesn't already exist, otherwise get it
    create_iam_user(iam_client, user_name)
    # create AWS keys for user if they don't have them
    access_key_id, secret_access_key = get_user_aws_keys(iam_client, user_name)
    # upload public ssh key (if applicable)
    if ssh_key:
        ssh_key_id = upload_user_ssh_key(iam_client, user_name, ssh_key)
    else:
        ssh_key_id = None
    # add user to group if they are not already a member
    add_user_to_group(iam_client, group_name, user_name)
    # email user(s)
    send_granted_email(ses_client, user_name, email, access_key_id, secret_access_key, ssh_key_id, repo_name)

def revoke_access_from_user(iam_client, ses_client, repo_name, user_name, email, region):
    group_name = GROUP_NAME_PREFIX + repo_name
    if interactive:
        print("going to remove user ({0}) from group ({1})".format(user_name, group_name))
        user_choice = raw_input('do you wish to continue (y/n)? ').upper()
        while user_choice != 'Y' and user_choice != 'N':
            user_choice = raw_input('please enter (y/Y) or (n/N): ').upper()
        if user_choice == 'N':
            sys.exit("okay - NOT removing user ({0}) from group ({1})".format(user_name, group_name))
        else:
            verbose_print("okay - removing user ({0}) from group ({1})".format(user_name, group_name))
    # remove user from group if they are a member
    remove_user_from_group(iam_client, group_name, user_name)
    # email user(s)
    send_revoked_email(ses_client, user_name, email, repo_name)

def main():
    global verbose_print
    global debug_print
    global interactive
    # parse command line arguments
    description = 'create an AWS CodeCommit repo and grant/revoke access to/from it'
    parser = argparse.ArgumentParser(description=description)
    optional = parser._action_groups.pop()
    required = parser.add_argument_group('required arguments')
    #mut_exc_grp = parser.add_mutually_exclusive_group(required=True)
    #mut_exc_grp.add_argument(
    #    '--grant',
    #    action='store_true',
    #    help='grant (add) user access to CodeCommit repo')
    #mut_exc_grp.add_argument(
    #    '-r', '--revoke',
    #    action='store_true',
    #    help='revoke (remove) user access to CodeCommit repo')
    required.add_argument(
        '-rn', '--repo-name',
        default=None,
        help='name of CodeCommit repo to add user too')
    required.add_argument(
        '-a', '--add',
        action='store_true',
        help='grant user access to CodeCommit repo')
    required.add_argument(
        '-r', '--remove',
        action='store_true',
        help='revoke user access to CodeCommit repo')
    #required.add_argument(
    #    'command',
    #    #required=True,
    #    choices=set(('grant','revoke')),
    #    help='grant (add) or revoke (remove) user access to CodeCommit repo')
    required.add_argument(
        '-un', '--user-name',
        default=None,
        help='AWS console user ID of user being added/removed to/from repo access')
    required.add_argument(
        '-e', '--email',
        default=None,
        help='E-mail address of user being added/removed to/from repo access')
    required.add_argument(
        '-c', '--config',
        help='file containing a list of repos/users to add/remove (format: YAML)')
    optional.add_argument(
        '-rd', '--repo-desc',
        default='Repo for collaborative development',
        help='repository description')
    optional.add_argument(
        '-s', '--ssh-key',
        default=None,
        help='file name containing a public SSH key the user to upload to AWS')
    optional.add_argument(
        '--region',
        default=DEFAULT_REGION,
        help='AWS region of the CodeCommit repo (uses AWS env settings or default: {0})'.format(DEFAULT_REGION))
    optional.add_argument(
        '-i', '--interactive',
        action='store_true',
        help='run interactively: show user changes and ask for verification to continue (useful when revoking access)')
    optional.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='turn on verbose output')
    optional.add_argument(
        '-d', '--debug',
        action='store_true',
        help='turn on debug output')
    optional.add_argument(
        '--dry-run',
        action='store_true',
        help='do NOT execute the commands - perform a dry-run')
    parser._action_groups.append(optional)
    args = parser.parse_args()

    # set up debug printing
    debug = args.debug
    if debug:
        def debug_print(*args):
            print "debug: ",
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
            print "info: ",
            for arg in args:
                print arg,
            print
        verbose_print('verbosity turned on')
    else:
        verbose_print = lambda *a: None	# do nothing function

    # set up vars
    repo_name = args.repo_name
    repo_desc = args.repo_desc
    user_name = args.user_name
    email = args.email
    ssh_key = args.ssh_key
    config = args.config
    add = args.add
    remove = args.remove
    region = args.region
    interactive = args.interactive
    dry_run = args.dry_run
    if dry_run:
        sys.exit("sorry: option '--dry-run' is not supported yet")
        verbose_print('performing dry-run')

    # verify proper usage
    if add and remove:
        parser.error("options '-a/--add' and '-r/--remove' are mutually exclusive - pick one")
    if not add and not remove:
        parser.error("options '-a/--add' or '-r/--remove' required")
    if (repo_name or user_name or email) and config:
        parser.error("specify either ('-rn/--repo-name', -un/--user-name' and '-e/--email') or '-c/--config' but not both")
    if not repo_name and not user_name and not email and not config:
        parser.error("options ('-rn/--repo-name', -un/--user-name' and '-e/--email') or '-c/--config' required")
    if config:
        verbose_print('using config file')
    else:
        if not repo_name and not user_name and not email:
            parser.error("options ('-rn/--repo-name', -un/--user-name' and '-e/--email') or '-c/--config' required")

    # connect to the AWS CodeCommit service
    codecommit_client = create_boto_service_client('codecommit', region)
    # connect to the AWS IAM service
    iam_client = create_boto_service_client('iam', region)
    # connect to the AWS SES service
    ses_client = create_boto_service_client('ses', DEFAULT_SES_REGION)

    # perform the add(s)/remove(s)
    if config:
        # verify/try/read config file
        try:
            with open(config, 'r') as config_file:
                yaml_config = config_file.read()
                configuration = yaml.load(yaml_config)
                config_file.close()
        except IOError as e:
            sys.exit("exception(IOError): can't open file ({0}): {1}".format(config, e))
        except Exception as e:
            debug_print("exception(Catch All): trying to open file ({0})".format(config))
            debug_print("error: class ({0}) name ({1})".format(e.__class__, e.__class__.__name__))
            sys.exit("error: {0}".format(e))

        if configuration.has_key('repos'):
            for repo in configuration['repos']:
                if repo.has_key('name'):
                    repo_name = repo['name']
                else:
                    sys.exit("error: did not find repo 'name' setting in config file ({0})".format(config))
                if repo.has_key('description'):
                    repo_desc = repo['description']
                else:
                    repo_desc = 'Repo for collaborative development'
                if repo.has_key('users'):
                    for user in repo['users']:
                        if user.has_key('user'):
                            user_name = user['user']
                        else:
                            sys.exit("error: did not find user 'name' setting for repo ({0}) users in config file ({1})".format(repo_name, config))
                        if user.has_key('email'):
                            email = user['email']
                        else:
                            sys.exit("error: did not find user 'email' setting for repo ({0}) users in config file ({1})".format(repo_name, config))
                        if user.has_key('sshkey'):
                            ssh_key = user['sshkey']
                        else:
                            ssh_key = None
                        if add:
                            grant_access_to_user(codecommit_client, iam_client, ses_client, repo_name, repo_desc, user_name, email, ssh_key, region)
                        elif remove:
                            revoke_access_from_user(iam_client, ses_client, repo_name, user_name, email, region)
                        else:
                            sys.exit("fatal error: don't know what to do (i.e. 'add' or 'remove'")
                else:
                    sys.exit("error: no users specified for repo ({0}) in config file ({1})".format(repo_name, config))
        else:
            sys.exit("error: no repos specified in config file ({0})".format(config))
    else:
        if add:
            grant_access_to_user(codecommit_client, iam_client, ses_client, repo_name, repo_desc, user_name, email, ssh_key, region)
        elif remove:
            revoke_access_from_user(iam_client, ses_client, repo_name, user_name, email, region)
        else:
            sys.exit("fatal error: don't know what to do (i.e. 'add' or 'remove'")

if __name__ == '__main__':
    main()
