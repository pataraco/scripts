#!/usr/bin/env python
# NOTE: this script iw WIP and NOT done
"""
    Description:
        Quick/dirty script to get/check the expiration dates of the
        certificates used by any AWS resources

    Usage:
        1. set up your AWS credentials/environment
        2. run the script

    Requirements:
        - proper IAM access to describe specific AWS services/resource

    ToDo:
        - add proper/specific error exception handling
"""

import argparse
import os
from datetime import datetime
import pytz
from tabulate import tabulate
import boto3


# set globals
BLU = '\x1b[1;34m'  # blue, bold
D2E = '\x1b[0K'     # delete to EOL
GRN = '\x1b[1;32m'  # green, bold
NRM = '\x1b[m'      # normal
RBG = '\x1b[1;101m' # red background, bold
RED = '\x1b[1;31m'  # red, bold
YLW = '\x1b[1;33m'  # yellow, bold
USAGE = "usage: $0 [-h] [-p AWS_PROFILE] [-r REGION]"
DEFAULT_REGION = os.getenv('AWS_DEFAULT_REGION') or 'us-west-2'


def add_color(string):
    """replaces specific words with highligthed words using ASCII escapes."""
    replacements = (
        ('EXPIRED', f'{RBG}EXPIRED{NRM}'),
        ('URGENT', f'{RED}URGENT{NRM}'),
        ('CAUTION', f'{YLW}CAUTION{NRM}'),
        ('SAFE', f'{GRN}SAFE{NRM}'),
        ('RELAX', f'{BLU}RELAX{NRM}'))
    for replacement in replacements:
        string = string.replace(*replacement)
    return string


# parse command line arguments
parser_description = 'get the expiration dates of AWS load balancers'
parser = argparse.ArgumentParser(description=parser_description)
parser.add_argument(
    '-r', '--region',
    default=DEFAULT_REGION,
    help='specify which region to search')
parser.add_argument(
    '-c', '--color',
    action='store_true',
    default=False,
    help='colorize/highlight the output')
args = parser.parse_args()


# set up some global vars
region = args.region
colorize = args.color
all_certs = {}  # indexed by their ARN and containing thier expiration dates


# get/set boto clients
iam = boto3.client('iam')
acm = boto3.client('acm', region_name=region)
elb = boto3.client('elb', region_name=region)
elbv2 = boto3.client('elbv2', region_name=region)


# get all server certificates (IAM)
paginator = iam.get_paginator('list_server_certificates')
page_iter = paginator.paginate()
for page in page_iter:
    # for cert in iam.list_server_certificates()['ServerCertificateMetadataList']
    for cert in page['ServerCertificateMetadataList']:
        # get the name, ID and expiration date of the cert
        expiration_date = cert['Expiration']
        name = cert['ServerCertificateName']
        cert_id = cert['ServerCertificateId']
        name = f'{name} [{cert_id}]'
        # show progress
        print(
            f'getting/processing all [IAM] server certificates:'
            f' {name}{D2E}', end='\r'
        )
        # save it in the dict
        all_certs[cert['Arn']] = {
            'name': name,
            'exp': expiration_date,
            'users': []
        }


# get all SSL/TLS certificates (ACM)
paginator = acm.get_paginator('list_certificates')
page_iter = paginator.paginate()
for page in page_iter:
    # for cert in acm.list_certificates()['CertificateSummaryList']:
    for cert in page['CertificateSummaryList']:
        # get the cert description and specifically,
        # the domain (name), ID and expiration date (exp)
        certificate = acm.describe_certificate(
            CertificateArn=cert['CertificateArn'])['Certificate']
        expiration_date = certificate['NotAfter']
        domain_name = certificate['DomainName']
        cert_id = cert['CertificateArn'].split('/')[1]
        name = f'{domain_name} [{cert_id}]'
        # show progress
        print(
            f'getting/processing all [ACM] SSL/TLS certificates:'
            f' {name}{D2E}', end='\r')
        # save it in the dict
        all_certs[cert['CertificateArn']] = {
            'name': name,
            'exp': expiration_date,
            'users': []
        }
        # # get the users
        # # (arn format of relevant resources)
        # # arn:aws:elasticloadbalancing:${Rgn}:${Acct}:loadbalancer/${Name}
        # # arn:aws:elasticloadbalancing:${Rgn}:${Acct}:loadbalancer/app/${Name}/${ID}
        # # arn:aws:elasticloadbalancing:${Rgn}:${Acct}:loadbalancer/net/${Name}/${ID}
        # # arn:aws:cloudfront::${Acct}:distribution/${ID}
        # in_use_by = certificate.get('InUseBy')
        # for user in in_use_by:
        #     # get all ARNs that are NOT classic load balancers
        #     # (since those have already been processed above)
        #     service = user.split(':')[2]
        #     if service == 'cloudfront':
        #         resource = 'CloudFront'
        #         name = user.split(':')[5].split('/')[1]
        #         all_certs[cert['CertificateArn']]['users'].append(
        #             f'{name} ({resource})')
        #     elif service == 'elasticloadbalancing':
        #         # classic LB ARN names only have 2 last
        #         # values (e.g. loadbalancer/${name})
        #         if len(user.split(':')[5].split('/')) > 2:
        #             lb_type = user.split(':')[5].split('/')[1]
        #             if lb_type == 'app':
        #                 resource = 'ALB'
        #             elif lb_type == 'net':
        #                 resource = 'NLB'
        #             else:
        #                 resource = 'UNK'
        #             name = user.split(':')[5].split('/')[2]
        #             all_certs[cert['CertificateArn']]['users'].append(
        #                 f'{name} ({resource})')


# check all the classic load balancers
paginator = elb.get_paginator('describe_load_balancers')
page_iter = paginator.paginate()
for page in page_iter:
    # for load_balancer in elb.describe_load_balancers()['LoadBalancerDescriptions']:
    for load_balancer in page['LoadBalancerDescriptions']:
        # get name and listeners
        lb_name = load_balancer['LoadBalancerName']
        listeners = load_balancer.get('ListenerDescriptions')
        # show progress
        print(
            f'getting/processing all classic load balancers:'
            f' {lb_name}{D2E}', end='\r')
        # check for and get certs in use
        for listener in listeners:
            cert_arn = listener['Listener'].get('SSLCertificateId')
            if cert_arn:
                port = listener['Listener'].get('LoadBalancerPort')
                all_certs[cert_arn]['users'].append(f'{lb_name} [{port}] (CLB)')


# check all the ALB/NLB (V2) load balancers
paginator = elbv2.get_paginator('describe_load_balancers')
for page in paginator.paginate():
    for load_balancer in page['LoadBalancers']:
        # get arn, name and listeners
        lb_arn = load_balancer['LoadBalancerArn']
        lb_name = load_balancer['LoadBalancerName']
        lb_type = load_balancer['Type']
        if lb_type == 'application':
            resource = 'ALB'
        elif lb_type == 'network':
            resource = 'NLB'
        else:
            resource = 'UNK'
        # show progress
        print(
            f'getting/processing all ALB/NLB load balancers:'
            f' {lb_name}{D2E}', end='\r')
        listeners_paginator = elbv2.get_paginator('describe_listeners')
        for listeners_page in listeners_paginator.paginate(LoadBalancerArn=lb_arn):
            for listener in listeners_page['Listeners']:
                certs = listener.get('Certificates')
                if certs:
                    port = listener.get('Port')
                    for cert in certs:
                        all_certs[cert['CertificateArn']]['users'].append(f'{lb_name} [{port}] ({resource})')


# print out all the certs and their expiratons and the LBs that use them
now = pytz.utc.localize(datetime.today())
table_rows = []
for arn, val in all_certs.items():
    expiration_delta = val['exp'] - now
    expiration_delta_days = expiration_delta.days
    if expiration_delta_days < 0:
        stat = 'EXPIRED'
    elif expiration_delta_days < 30:
        stat = 'URGENT'
    elif expiration_delta_days < 60:
        stat = 'CAUTION'
    elif expiration_delta_days <= 180:
        stat = 'SAFE'
    elif expiration_delta_days > 180:
        stat = 'RELAX'
    exp_date = val['exp'].date()
    name = val['name']
    users = val['users']
    cert_type = arn.split(':')[2]
    for user in users:
        expires = f'{exp_date.month:02d}/{exp_date.day:02d}/{exp_date.year}'
        expires = f'{expires:10} ({expiration_delta_days:4} days) [{stat}]'
        cert = f'{name} ({cert_type})'
        table_rows.append([user, cert, expires])


# print out the results
if table_rows:
    headers = ['Resource', 'Certificate', 'Expiration']
    if colorize:
        print(add_color(tabulate(table_rows, headers, tablefmt='psql')))
    else:
        print(tabulate(table_rows, headers, tablefmt='psql'))
else:
    print(f'no certs in use in this region: {region}{D2E}')
