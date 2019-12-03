#!/bin/env python
#
# Description:
#	Change the user data script for an AWS Launch Configuration
#
# Usage:
#   aws_update_lc_user_data_script.py [-h] [--dry-run] [-a ASG_NAME] [-i] [-v]
#                                     -l LC_NAME
#                                     -r REGION
#                                     -u USER_DATA_SCRIPT
#
# Requirements:
#	Must have AWS credentials (keys) for the AWS account in which the
#	Launch Configuration you are trying to modify resides
#	The AWS credentials/environment must be set (i.e. with environment vars)
#
# TODO:
#	- Add option to specify an AWS profile to use to obtain keys
#	- Add code to make sure AWS environment set (Environment vars or using a profile)
#	- check for 'NextToken' field when getting list of autoscaling groups
#     that use the launch configuration, if found, use pagination

import argparse
import base64
import boto3
import copy
import difflib
import sys

def copy_existing_lc(as_client, lc_name):
    # copy existing launch configuraton
    verbose_print('Capturing/Saving launch configuration: {0}'.format(lc_name))
    try:
        orig_lc = as_client.describe_launch_configurations(LaunchConfigurationNames=[lc_name])['LaunchConfigurations'][0]
    except IndexError:
        sys.exit('Exiting: the launch configuration ({0}) does not exist'.format(lc_name))
    except Exception as e:
        sys.exit('AWS Error - cannot describe launch configurations: {0}'.format(e))
    verbose_print('\tHere\'s the ARN: {0}'.format(orig_lc['LaunchConfigurationARN']))
    verbose_print('\tand the Created Time: {0}'.format(orig_lc['CreatedTime']))
    verbose_print('Deleting unneccesary captured dict keys/vals from the launch configuration')
    del orig_lc['LaunchConfigurationARN']
    del orig_lc['CreatedTime']
    del orig_lc['KernelId']
    del orig_lc['RamdiskId']
    return orig_lc

def get_compare_user_data_scripts(orig_uds, orig_uds_file_name, new_uds_file_name, interactive):
    # save a copy of the user data script for comparison
    verbose_print('Getting/Decoding/Saving user data script')
    verbose_print('\tGetting user data script from launch configuration')
    try:
        with open(orig_uds_file_name, 'w') as orig_uds_file:
            verbose_print('\tDecoding user data script with base64')
            verbose_print('\t  and writing to file: {0}'.format(orig_uds_file_name))
            orig_uds_file.write(base64.b64decode(orig_uds))
    except IOError as e:
        sys.exit('Cannot open file ({0}) for writing: {1}'.format(orig_uds_file_name, e.strerror))
    # open specified user data script for comparison
    verbose_print('Opening specified new user data script file: {0}'.format(new_uds_file_name))
    try:
        with open(new_uds_file_name, 'r') as new_uds_file:
            new_uds = new_uds_file.read()
    except IOError as e:
        sys.exit('Cannot open file ({0}) for reading: {1}'.format(new_uds_file_name, e.strerror))
    # show user data script changes if running verbose
    if verbose or interactive:
        print 'Here are the changes you are making to the user data script'
        print '------- ------- -------'
        with open(orig_uds_file_name) as from_file, open(new_uds_file_name) as to_file:
            for diff in difflib.unified_diff(from_file.readlines(), to_file.readlines(), fromfile=orig_uds_file_name, tofile=new_uds_file_name, n=2):
                sys.stdout.write(diff)                                                          
        print '------- ------- -------'
    # return the new user data script
    return new_uds

def get_asgs_to_modify(as_client, asg_name, lc_name):
    # returns the list of ASG(s) to modify and whether or not to delete the orig LC
    # get list of autoscaling groups using the launch configuration
    verbose_print('Getting list of auto scaling groups using the launch configuration')
    # get the list of auto scaling groups
    try:
        asgs = as_client.describe_auto_scaling_groups()['AutoScalingGroups']
    except Exception as e:
        sys.exit('AWS Error - cannot describe auto scaling groups: {0}'.format(e))
    # go through the list and look for the launch configuration
    asgs_using_lc = []
    for asg in asgs:
        if asg['LaunchConfigurationName'] == lc_name:
            asgs_using_lc.append(asg['AutoScalingGroupName'])
    if verbose:
        # display findings
        print 'Found these auto scaling groups using the launch configuration:', lc_name
        for asgn in asgs_using_lc:
            print '\t', asgn
    if len(asgs_using_lc) > 1 and asg_name:
        if verbose:
            print 'There\'s more than one auto scaling group using the launch configuration'
            print '  but you only want to change this one:', asg_name
            print '  so NOT deleting the original launch configuration:', lc_name
            print '  and going to create a NEW launch configuration'
        else:
            print 'NOT deleting original launch configuration and creating NEW'
        deleting_orig_lc = False
    else:
        deleting_orig_lc = True
    # sanity check - did user specify an ASG name that's actually using the LC they specified?
    if asg_name and (asg_name not in asgs_using_lc):
        sys.exit('Specified auto scaling group ({0}) is NOT using launch configuration: {1}'.format(asg_name,lc_name))
    # set the list of ASG(s) to modify
    if asg_name:
        asgs_to_modify = [asg_name]
    else:
        asgs_to_modify = asgs_using_lc
    # and return it
    return asgs_to_modify, deleting_orig_lc

def prep_lc(lc_to_copy, user_data_to_use, name_to_use, type_of_lc):
    # prepare a launch configuration by copying one and modifying the user data and name
    verbose_print('Prepping {0} launch configuration'.format(type_of_lc))
    verbose_print('\tCopying orig launch configuration')
    prepped_lc = copy.deepcopy(lc_to_copy)
    # update the user data script on the launch configuration copy
    verbose_print('\tUpdating the user data script')
    prepped_lc['UserData'] = user_data_to_use
    # update the name of the launch configuration
    verbose_print('\tUpdating the launch configuration name to: {0}'.format(name_to_use))
    prepped_lc['LaunchConfigurationName'] = name_to_use
    # return the prepped LC
    return prepped_lc

def create_lc(as_client, lc, dry_run):
    lc_name = lc['LaunchConfigurationName']
    if dry_run:
        verbose_print('\tdry-run: NOT creating the launch configuration: {0}'.format(lc_name))
    else:
        verbose_print('\tCreating the launch configuration: {0}'.format(lc_name))
        try:
            response = as_client.create_launch_configuration(**lc)
        except Exception as e:
            sys.exit('AWS Error - cannot create launch configuration ({0}): {1}'.format(lc_name,e))

def update_asgs(as_client, asgs, lc, dry_run):
    lc_name = lc['LaunchConfigurationName']
    for asg_name in asgs:
        if dry_run:
            verbose_print('\tdry-run: NOT modifying ASG: {0} to use LC: {1}'.format(asg_name,lc_name))
        else:
            verbose_print('\tModifying ASG: {0} to use LC: {1}'.format(asg_name,lc_name))
            try:
                response = as_client.update_auto_scaling_group(AutoScalingGroupName=asg_name, LaunchConfigurationName=lc_name)
            except Exception as e:
                sys.exit('AWS Error - cannot update auto scaling group ({0}): {1}'.format(asg_name,e))

def delete_lc(as_client, lc, dry_run):
    lc_name = lc['LaunchConfigurationName']
    if dry_run:
        verbose_print('\tdry-run: NOT deleting launch configuration: {0}'.format(lc_name))
    else:
        verbose_print('\tDeleting launch configuration: {0}'.format(lc_name))
        try:
            response = as_client.delete_launch_configuration(LaunchConfigurationName=lc_name)
        except Exception as e:
            sys.exit('AWS Error - cannot delete launch configuration ({0}): {1}'.format(lc_name,e))

def verbose_print(str):
    if verbose:
        print (str)

def main():
    global verbose
    # parse command line arguments
    description = 'Change the user data script for an AWS Launch Configuration'
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='do NOT execute the commands - perform a dry-run')
    parser.add_argument(
        '-a', '--asg-name',
        default=False,
        help='name of a specific auto scaling group to modify')
    parser.add_argument(
        '-i', '--interactive',
        action='store_true',
        help='run interactively: show user data script changes and ask for verification to continue')
    parser.add_argument(
        '-l', '--lc-name',
        required=True,
        help='name of launch configuration to modify')
    parser.add_argument(
        '-r', '--region',
        required=True,
        help='AWS region containing the launch configuration')
    parser.add_argument(
        '-u', '--user-data-script',
        required=True,
        help='path to and name of user data script to use')
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='turn on verbosity')
    args = parser.parse_args()
    # set up some vars
    verbose = args.verbose
    verbose_print('verbosity turned on')
    dry_run = args.dry_run
    if dry_run:
        verbose_print('performing dry-run')
    interactive = args.interactive
    asg_name = args.asg_name
    lc_name = args.lc_name
    region = args.region
    new_uds_file_name = args.user_data_script
    orig_uds_file_name = '/tmp/{0}-uds-orig.txt'.format(lc_name)

    # connect to the autoscaling service
    as_client = boto3.client('autoscaling', region_name=region)
    # copy existing launch configuraton
    orig_lc = copy_existing_lc(as_client, lc_name)
    # get the user data scripts
    orig_uds = orig_lc['UserData']
    new_uds = get_compare_user_data_scripts(orig_uds, orig_uds_file_name, new_uds_file_name, interactive)
    # if running interactively - ask to continue after displaying UDS changes
    if interactive:
        user_choice = raw_input('Do you wish to continue (y/n)? ').upper()
        while user_choice != 'Y' and user_choice != 'N':
            user_choice = raw_input('Please enter (y/Y) or (n/N): ').upper()
        if user_choice == 'N':
            sys.exit('OK - NOT continuing.\nOriginal user data script saved to: {0}'.format(orig_uds_file_name))
        else:
            verbose_print('\tContinuing with update(s)')
    # get the list of ASG(s) to modify and whether or not we'll be deleting the orig LC
    asgs_to_modify, deleting_orig_lc = get_asgs_to_modify(as_client, asg_name, lc_name)
    # if deleting the original LC, then need to use a temp LC
    if deleting_orig_lc:
        # need a temp LC: set the name of the temp LC to "orig_lc_name"-TEMP
        temp_lc_name = '{0}-TEMP'.format(lc_name)
        # prep temp LC
        temp_lc = prep_lc(orig_lc, new_uds, temp_lc_name, 'temp')
        # create a temporary launch configuraton with new user data script
        print 'Creating temporary launch configuration'
        create_lc(as_client, temp_lc, dry_run)
        # modify the ASG(s) to use the new temp launch configuration
        print 'Modifying ASG(s)s to use temporary launch configuration'
        update_asgs(as_client, asgs_to_modify, temp_lc, dry_run)
        # delete the old/orig launch configuration
        print 'Deleting old launch configuration'
        delete_lc(as_client, orig_lc, dry_run)
        # set the name of the new LC to the same as the orig
        new_lc_name = lc_name
    else:
        if verbose:
            print 'Since NOT Deleting old launch configuration and creating a NEW,'
            print '  don\'t need to modify ASG(s) to use a temporary launch configuration'
        else:
            print 'NOT modifying ASG(s) to use a temporary launch configuration'
        print 'NOT Deleting old launch configuration, used by other auto scaling group(s)'
        # set the name of the new LC to "orig_lc_name"-NEW
        new_lc_name = '{0}-NEW'.format(lc_name)

    # prep new LC
    new_lc = prep_lc(orig_lc, new_uds, new_lc_name, 'new')
    # create the new permanent launch configuration
    print 'Creating new permanent launch configuration with new user data'
    create_lc(as_client, new_lc, dry_run)
    # update the ASG(s) to use the NEW permanent launch configuration
    print 'Modifying ASG(s) to use new permanent launch configuration'
    update_asgs(as_client, asgs_to_modify, new_lc, dry_run)
    # delete the temporary LC if created/used
    if deleting_orig_lc:
        # delete the temporary launch configuration
        print 'Deleting temporary launch configuration'
        delete_lc(as_client, temp_lc, dry_run)

if __name__ == '__main__':
    main()
