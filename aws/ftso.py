#!/bin/env python

import boto3
import botocore.exceptions
import os
import sys

DEFAULT_REGION = 'us-east-1'
nonexistent_repo = 'nonexistent'
new_repo = 'raco_test_repo_please_delete'
repo_name = 'repo_tcs_adev'

# if user specifies region on command line use that
# otherwise check if AWS_DEFAULT_REGION set that has precedende
# if not set then setting in AWS config is used
# is not set region gto default val
#try:
#    env_var = 'AWS_DEFAULT_REGION'
#    region = os.environ[env_var]
#    print("AWS region environment set: {0}").format(region)
#except KeyError as e:
#    print("AWS region environment NOT set: {0}").format(env_var)
#    print("error: {0}").format(e)
#    #region = DEFAULT_REGION
#    #print("setting region to default value: {0}").format(region)
#except Exception as e:
#    print("catch all exception")
#    print("couldn't get/set region")
#    print("error: {0}").format(e)
#    print("error class: {0}").format(e.__class__)

#def create_boto_service_client(service, region):
#    try:
#        try:
#           client = boto3.client(service_name=service, region_name=region)
#           print("created {0} boto service client with region defined: {1}").format(service, region)
#        except NameError as e:
#           client = boto3.client(service)
#           print("created {0} boto service client without region define using aws config").format(service)
#    except botocore.exceptions.NoRegionError as e:
#        print("can NOT create {0} boto service client").format(service)
#        print("AWS region environment NOT set")
#        print("and region not defined in aws config")
#        print("error: {0}").format(e)
#    except Exception as e:
#        print("catch all exception")
#        print("couldn't create {0} boto service client").format(service)
#        print("error: {0}").format(e)
#        print("error class: {0}").format(e.__class__)
#    return client

try:
    service = 'codecommit'
    try:
       cc_client = boto3.client(service_name=service, region_name=region)
       print("created {0} boto service client with region defined: {1}").format(service, region)
    except NameError as e:
       cc_client = boto3.client(service_name=service)
       print("created {0} boto service client without region defined using aws config").format(service)
except botocore.exceptions.NoRegionError as e:
    print("can NOT create {0} boto service client").format(service)
    print("AWS region environment NOT set AND region not defined in AWS config")
    print("error: {0}").format(e)
except botocore.exceptions.ProfileNotFound as e:
    #print("error: {0}".format(e))
    sys.exit("error (AWS profile): {0}".format(e))
# except NameError as e:
#     print("can NOT create {0} boto service client").format(service)
#     print("variable is not defined")
#     print("error: {0}").format(e)
except Exception as e:
    print("catch all exception")
    print("couldn't create {0} boto service client").format(service)
    print("error: {0}").format(e)
    print("error class: {0}").format(e.__class__)

try:
    repo = cc_client.get_repository(repositoryName=nonexistent_repo)
    print("repo exists: {0}").format(nonexistent_repo)
    repo_arn = repo['repositoryMetadata']['Arn']
    print("repo arn: {0}").format(repo_arn)
except botocore.exceptions.NoCredentialsError as e:
    print("AWS credentials NOT set: can't get repo named: {0}").format(nonexistent_repo)
    print("error: {0}").format(e)
except botocore.exceptions.ClientError as e:
    print("couldn't get repo named: {0}").format(nonexistent_repo)
    e_code = e.response['Error']['Code']
    if e_code == 'RepositoryDoesNotExistException':
        print("repo '{0}' does NOT exist").format(nonexistent_repo)
    elif e_code == 'AccessDeniedException':
        print("you don't have permission to get codecommit repo info")
    else:
        print("because of this: {0}").format(e_code)
    print("error: {0}").format(e)
except Exception as e:
    print("catch all exception")
    print("couldn't get repo named: {0}").format(nonexistent_repo)
    print("error: {0}").format(e)
    print("error class: {0}").format(e.__class__)
    print("error name: {0}").format(e.__class__.__name__)

try:
    repo = cc_client.get_repository(repositoryName=repo_name)
    print("repo exists: {0}").format(repo_name)
    repo_arn = repo['repositoryMetadata']['Arn']
    print("repo arn: {0}").format(repo_arn)
except botocore.exceptions.NoCredentialsError as e:
    print("AWS credentials NOT set: can't get repo named: {0}").format(repo_name)
    print("error: {0}").format(e)
except botocore.exceptions.ClientError as e:
    print("couldn't get repo named: {0}").format(repo_name)
    e_code = e.response['Error']['Code']
    if e_code == 'RepositoryDoesNotExistException':
        print("repo '{0}' does NOT exist").format(repo_name)
    elif e_code == 'AccessDeniedException':
        print("you don't have permission to get codecommit repo info")
    else:
        print("because of this: {0}").format(e_code)
    print("error: {0}").format(e)
except Exception as e:
    print("catch all exception")
    print("couldn't get repo named: {0}").format(repo_name)
    print("error: {0}").format(e)
    print("error class: {0}").format(e.__class__)

try:
    repo = cc_client.create_repository(repositoryName=new_repo)
    repo_arn = repo['repositoryMetadata']['Arn']
    print("created repo: {0} ({1})").format(new_repo, repo_arn)
except botocore.exceptions.NoCredentialsError as e:
    print("AWS credentials NOT set: can't create repo named: {0}").format(repo_name)
    print("error: {0}").format(e)
except botocore.exceptions.ClientError as e:
    print("couldn't create repo named: {0}").format(new_repo)
    e_code = e.response['Error']['Code']
    if e_code == 'RepositoryNameExistsException':
        print("repo '{0}' already exists").format(new_repo)
        #raise(e)
    elif e_code == 'AccessDeniedException':
        print("you don't have permission to create codecommit repos")
    else:
        print("because of this: {0}").format(e_code)
#     print("error: {0}").format(e)
#     print("error class: {0}").format(e.__class__)
#     print("error name: {0}").format(e.__class__.__name__)
#     print("error msg: {0}").format(e.message)
#     print("error response: {0}").format(e.response)
#     print("error code: {0}").format(e.response['Error']['Code'])
       
except Exception as e:
    print("catch all exception")
    print("couldn't create repo named: {0}").format(new_repo)
    print("error: {0}").format(e)
    print("error class: {0}").format(e.__class__)
    print("error name: {0}").format(e.__class__.__name__)

try:
    service = 'iam'
    iam_client = boto3.client(service_name=service)
    print("created {0} boto service client using aws config").format(service)
except Exception as e:
    print("catch all exception")
    print("couldn't create {0} boto service client").format(service)
    print("error: {0}").format(e)
    print("error class: {0}").format(e.__class__)

try:
    #group_name = 'CodeCommit_' + nonexistent_repo
    group_name = 'CodeCommit_' + repo_name
    group = iam_client.get_group(GroupName=group_name)
    group_arn = group['Group']['Arn']
    print("IAM group '{0}' already exists ({1})").format(group_name, group_arn)
except botocore.exceptions.NoCredentialsError as e:
    print("AWS credentials NOT set: can't get group: {0}").format(group_name)
    print("error: {0}").format(e)
except botocore.exceptions.ClientError as e:
    print("couldn't get group named: {0}").format(group_name)
    e_code = e.response['Error']['Code']
    if e_code == 'NoSuchEntity':
        print("group '{0}' does NOT exist").format(group_name)
    elif e_code == 'AccessDenied':
        print("you don't have permission to get group info")
    else:
        print("because of this: {0}").format(e_code)
    print("error: {0}").format(e)
except Exception as e:
    print("catch all exception")
    print("couldn't get repo named: {0}").format(group_name)
    print("error: {0}").format(e)
    print("error class: {0}").format(e.__class__)
