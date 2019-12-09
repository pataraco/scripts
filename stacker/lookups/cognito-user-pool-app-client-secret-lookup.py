"""Stacker custom lookup to get a Cognito User Pool App Client Secret."""

import logging
from stacker.session_cache import get_session

TYPE_NAME = 'CognitoUserPoolAppClientSecret'
LOGGER = logging.getLogger(__name__)

def handler(value, provider, **kwargs):  # pylint: disable=W0613
    """ Lookup a Cognito User Pool App Client secret by UserPoolId::AppClientId.

    Need to specify the Cognito User Pool ID and App Client ID

    Region is obtained from the environment file

    [in the environment file]:
      region: us-west-2

    For example:

    [in the stacker yaml (configuration) file]:

      lookups:
        CognitoUserPoolAppClientSecret: lookups.instance-attribute-by-name-tag-lookup.handler

      stacks:
        variables:
          AppClientSecret: ${CognitoUserPoolAppClientSecret ${user-pool-id}::${app-client-id}}
    """

    user_pool_id = value.split('::')[0]
    app_client_id = value.split('::')[1]

    session = get_session(provider.region)
    cognito_client = session.client('cognito-idp')
    try:
        desc_user_pool_client_output = cognito_client.describe_user_pool_client(
                                    ClientId=app_client_id,
                                    UserPoolId=user_pool_id)
    except Exception as e:
        LOGGER.error('could not describe user pool client: %s', e)
        return 'error: could not describe user pool client'

    secret = desc_user_pool_client_output['UserPoolClient'].get('ClientSecret')
    if secret:
        LOGGER.debug('found user pool app client secret')
        return secret
    else:
        LOGGER.debug('did not find user pool app client secret')
        return 'not found'
