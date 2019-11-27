"""Custom lookup for getting SSM Parameters from a different account."""
import logging
from stacker.session_cache import get_session

LOGGER = logging.getLogger(__name__)


def handler(value, provider, context, **kwargs):  # pylint: disable=W0613
    """Cross account SSM Parameter Store look up handler."""
    """Format of value:

        <role_arn>@<ssm_parameter_name>

    For example:

        AppAMI: ${crssacctssm arn:aws:iam::5555555555:role/ssm-role@/infra/ami/windows/latest}  # noqa

    This lookup will assume an IAM role and use it to retrieve a SSM Parameter.
    The return value will be the parameter value as a string.
    """

    # Split value for the Role and Parameter Name
    try:
        role_arn, param_name = value.split('@', 1)
    except ValueError:
        raise ValueError('Invalid value for crssacctssm: {}. Must be in '
                         '<role_arn>@<ssm_parameter_name> format'.format(
                            value))

    # Use role_arn for sts assume role
    session = get_session(provider.region)
    sts_client = session.client('sts')
    LOGGER.info('Assuming Role: {}'.format(role_arn))
    response = sts_client.assume_role(
        RoleArn=role_arn,
        RoleSessionName='runway-ssm-get-param',
        DurationSeconds=900,
    )

    # Use tokens from assume role to create ssm GetParameter
    ssm_client = session.client(
        'ssm',
        aws_access_key_id=response['Credentials']['AccessKeyId'],
        aws_secret_access_key=response['Credentials']['SecretAccessKey'],
        aws_session_token=response['Credentials']['SessionToken'],
    )
    LOGGER.info('Looking up Parameter: {}'.format(param_name))
    param_resp = ssm_client.get_parameter(Name=param_name)

    # Return the value from the parameter
    LOGGER.debug(param_resp.get('Parameter', 'Error getting SSM Parameter'))
    param_value = param_resp['Parameter'].get('Value')
    return param_value
