"""Post build hook to add a lambda notification configuration to a S3 bucket."""
import logging
import boto3

# from stacker.session_cache import get_session
from stacker.lookups.handlers.output import handler as output_handler

LOGGER = logging.getLogger(__name__)


def configure_lambda_s3_notification(provider, context, **kwargs):
    """Configure lambda S3 notification event handler."""
    s3_client = boto3.client(service_name='s3', region_name=provider.region)

    if kwargs.get('LambdaArn'):
        instanceid = output_handler(
            kwargs.get('InstanceId'),
            provider=provider,
            context=context
        )
    else:
        LOGGER.warn('Missing required arguement: InstanceId')
        return False

    if kwargs.get('BucketName'):
        instanceid = output_handler(
            kwargs.get('InstanceId'),
            provider=provider,
            context=context
        )
    else:
        LOGGER.warn('Missing required arguement: InstanceId')
        return False

    if kwargs.get('SsmParamKey'):
        ssmparamkey = kwargs.get('SsmParamKey')
    else:
        LOGGER.warn('Missing required arguement: SsmParamKey')
        return False

    LOGGER.info('Attempting to save admin password for {} to SSM {}'.format(instanceid, ssmparamkey))

    getpwdataoutput = s3_client.get_password_data(InstanceId=instanceid)
    encryptedpw = base64.b64decode(getpwdataoutput['PasswordData'].strip())

    if encryptedpw:
        with open(PRIVATE_KEY_FILE, 'r') as privkeyfile:
            privatekey = rsa.PrivateKey.load_pkcs1(privkeyfile.read())
        decryptedpw = rsa.decrypt(encryptedpw, privatekey)
    else:
        LOGGER.warn('admin password not available.')
        return False

    try:
        putparamresponse = s3_client.put_parameter(
            Description='Windows Administrator password',
            Name=ssmparamkey,
            Overwrite=True,
            Type='SecureString',
            Value=decryptedpw)
        LOGGER.debug('%s', putparamresponse)
        LOGGER.info('SSM put parameter succeeded.')
    except Exception as e:
        LOGGER.info('%s', e)
        LOGGER.warn('SSM put parameter failed.')
        return False

    return True
