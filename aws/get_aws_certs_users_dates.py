#!/usr/bin/env python
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
        - add json output option
        - add option to only show certs expiring with N days
"""

import argparse
import os
from datetime import datetime, timedelta
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
MADEUP_CF_DEFAULT_CERT_ARN = 'arn:aws:cloudfront:us-east-1::certificate/default'


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
parser_description = 'get certificate expiration dates used for AWS load balancers, CloudFront distributions and API gateway custom domains'
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
all_certs = {}  # indexed by ARN & containing (short desc, exp date, and users)
iam_cert_arns = {}  # indexed by ID equal to the ARN - used to translate ID -> ARN


# get/set boto clients
apigateway = boto3.client('apigateway', region_name=region)
cloudfront = boto3.client('cloudfront')
elb = boto3.client('elb', region_name=region)
elbv2 = boto3.client('elbv2', region_name=region)
iam = boto3.client('iam')


# get all server certificates (IAM)
# example ARN = arn:aws:iam::AWS_ACCT:server-certificate/CERT_NAME
paginator = iam.get_paginator('list_server_certificates')
for page in paginator.paginate():
    # for cert in iam.list_server_certificates()['ServerCertificateMetadataList']
    for cert in page['ServerCertificateMetadataList']:
        # get the name, ID and expiration date of the cert
        expiration_date = cert['Expiration']
        name = cert['ServerCertificateName']
        cert_id = cert['ServerCertificateId']
        short_desc = f'{name} [{cert_id}]'
        # show progress
        print(
            f'getting/processing all [IAM] server certificates:'
            f' {short_desc}{D2E}', end='\r'
        )
        # save it in the dict
        all_certs[cert['Arn']] = {
            'short_desc': short_desc,
            'exp': expiration_date,
            'users': []
        }
        iam_cert_arns[cert_id] = cert['Arn']


# get all SSL/TLS certificates (ACM)
# example ARN = arn:aws:acm:REGION:AWS_ACCT:certificate/ID
for acm_region in list(set(['us-east-1', region])):
    acm = boto3.client('acm', region_name=acm_region)
    paginator = acm.get_paginator('list_certificates')
    for page in paginator.paginate():
        # for cert in acm.list_certificates()['CertificateSummaryList']:
        for cert in page['CertificateSummaryList']:
            # get the cert description and specifically,
            # the domain (name), ID and expiration date (exp)
            certificate = acm.describe_certificate(
                CertificateArn=cert['CertificateArn'])['Certificate']
            expiration_date = certificate['NotAfter']
            domain_name = certificate['DomainName']
            cert_id = cert['CertificateArn'].split('/')[1]
            short_desc = f'{domain_name} [{cert_id}]'
            # show progress
            print(
                f'getting/processing all [ACM] SSL/TLS certificates:'
                f' {short_desc}{D2E}', end='\r')
            # save it in the dict
            all_certs[cert['CertificateArn']] = {
                'short_desc': short_desc,
                'exp': expiration_date,
                'users': []
            }


# generate a place to store a CloudFront default certificate users
# example ARN = arn:aws:cloudfront:us-east-1::certificate/default
# the ARN and expiration date are made up - but i'm sure it's fine
cert_arn = MADEUP_CF_DEFAULT_CERT_ARN
short_desc = 'Default CloudFront Certificate (*.cloudfront.net)'
expiration_date = pytz.utc.localize(datetime.today() + timedelta(days=365))
# show progress
print(
    f'making up an ARN for the default CloudFront certificate:'
    f' {short_desc}{D2E}', end='\r')
# save it in the dict
all_certs[cert_arn] = {
    'short_desc': short_desc,
    'exp': expiration_date,
    'users': []
}


# check all the API gateway custom domain
resource = 'API GW'  # API Gareway (custom domain)
paginator = apigateway.get_paginator('get_domain_names')
for page in paginator.paginate():
    for api_gw_custom_domain in page['items']:
        # get name and listeners
        domain_name = api_gw_custom_domain['domainName']
        cert_arn = api_gw_custom_domain['certificateArn']
        domain_type = api_gw_custom_domain['endpointConfiguration']['types'][0]
        domain_status = api_gw_custom_domain['domainNameStatus']
        # show progress
        print(
            f'getting/processing all API gateway custom domains:'
            f' {domain_name}{D2E}', end='\r')
        # add results to list
        all_certs[cert_arn]['users'].append(
            f'{domain_name} [{domain_type}|{domain_status}] ({resource})')


# check all the classic load balancers
resource = 'CLB'  # Classic Load Balancer
paginator = elb.get_paginator('describe_load_balancers')
for page in paginator.paginate():
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
                all_certs[cert_arn]['users'].append(
                    f'{lb_name} [{port}] ({resource})')


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
            resource = 'Unknown'
        # show progress
        print(
            f'getting/processing all ALB/NLB load balancers:'
            f' {lb_name}{D2E}', end='\r')
        paginator_lbdl = elbv2.get_paginator('describe_listeners')
        for listeners_page in paginator_lbdl.paginate(LoadBalancerArn=lb_arn):
            for listener in listeners_page['Listeners']:
                certs = listener.get('Certificates')
                if certs:
                    port = listener.get('Port')
                    for cert in certs:
                        all_certs[cert['CertificateArn']]['users'].append(
                            f'{lb_name} [{port}] ({resource})')


# check all the CloudFront distributions
resource = 'CloudFront'
paginator = cloudfront.get_paginator('list_distributions')
for page in paginator.paginate():
    for distribution in page['DistributionList']['Items']:
        # get distribution id and certificate
        dist_id = distribution['Id']
        # show progress
        print(
            f'getting/processing all CloudFront Distributions:'
            f' {dist_id}{D2E}', end='\r')
        dist_alias_qty = distribution['Aliases']['Quantity']
        if dist_alias_qty != 0:
            dist_alias = distribution['Aliases']['Items'][0]
        else:
            dist_alias = 'no aliases'
        dist_cert = distribution.get('ViewerCertificate')
        if dist_cert:
            cert_source = dist_cert['CertificateSource']
            if cert_source == 'acm':
                cert_arn = dist_cert['ACMCertificateArn']
            elif cert_source == 'iam':
                cert_id = dist_cert['IAMCertificateId']
                cert_arn = iam_cert_arns[cert_id]
            elif cert_source == 'cloudfront':
                cert_arn = MADEUP_CF_DEFAULT_CERT_ARN
            all_certs[cert_arn]['users'].append(
                f'{dist_id} [{dist_alias}] ({resource})')


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
    short_desc = val['short_desc']
    users = val['users']
    cert_type = arn.split(':')[2]
    for user in users:
        expires = f'{exp_date.month:02d}/{exp_date.day:02d}/{exp_date.year}'
        expires = f'{expires:10} ({expiration_delta_days:4} days) [{stat}]'
        cert = f'{short_desc} ({cert_type})'
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
