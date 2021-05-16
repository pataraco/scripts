#!/usr/bin/env python

import os
import json
from urllib.parse import urlencode
from urllib.request import urlopen

CONSOLE_URL = 'https://console.aws.amazon.com/'
SIGNIN_URL = 'https://signin.aws.amazon.com/federation?'
LOGOUT_URL = 'https://console.aws.amazon.com/console/logout!doLogout'
SESSION_DURATION = 43200

creds = {
        'sessionId': os.environ['AWS_ACCESS_KEY_ID'],
        'sessionKey': os.environ['AWS_SECRET_ACCESS_KEY'],
        'sessionToken': os.environ['AWS_SESSION_TOKEN'],
    }
json_creds = json.dumps(creds)

params = {
    'Action': 'getSigninToken',
    'SessionType': 'json',
    'Session': json_creds,
    'SessionDuration': SESSION_DURATION
}
url = SIGNIN_URL + urlencode(params)
# print('--------- debug: temp url --------')
# print(url)

signin_token = json.loads(urlopen(url).read())['SigninToken']
# print('--------- debug: signin_token --------')
# print(signin_token)

params = {
    'Action': 'login',
    'SigninToken': signin_token,
    'Destination': CONSOLE_URL,
}
url = SIGNIN_URL + urlencode(params)
# print('--------- debug: final url --------')
print(url)
