#!/usr/bin/env python
"""
    Description:
        Find the AWS user who owns a specific AWS access key
"""

import sys
import boto3

D2E = '\x1b[0K'   # delete to EOL
HDC = '\x1b[?25l' # hide cursor
SHC = '\x1b[?25h' # show cursor

if len(sys.argv) == 2:
    target_key = sys.argv[1]
else:
    print(f'error: no target key given')
    print(f'usage: {sys.argv[0]} AWS_ACCESS_KEY')
    exit(1)

iam = boto3.client('iam')
users = iam.list_users()['Users']


def find_key(target_key):
    for user in users:
        key_paginator = iam.get_paginator('list_access_keys')
        for key_response in key_paginator.paginate(UserName=user['UserName']):
            for key in key_response['AccessKeyMetadata']:
                key_id = key['AccessKeyId']
                user_name = user['UserName']
                print(f'{HDC}{user_name} ({key_id}){D2E}', end = '\r')
                if key_id == target_key:
                    print(f'found: {user_name} ({target_key}){SHC}')
                    return True
    return False


if not find_key(target_key):
    print(f'not found: {target_key}{SHC}')
