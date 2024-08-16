import boto3
import logging
from botocore.exceptions import ClientError, NoCredentialsError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_service(service_name, function, **kwargs):
    logger.info(f"\nTesting {service_name} API")
    try:
        response = function(**kwargs)
        logger.info(f"Response from {service_name}: {response}")
    except ClientError as e:
        logger.error(f"ClientError in {service_name}: {e}")
    except NoCredentialsError:
        logger.error(f"No credentials found for {service_name}")
    except Exception as e:
        logger.error(f"Error in {service_name}: {e}")

if __name__ == "__main__":
    # Ask user for input
    region_code = input("Set your region: ").lower().strip()

    print(f"\nUsing the following settings:")
    print(f"Region Code: {region_code}\n")

    # Create boto3 clients
    ec2 = boto3.client('ec2', region_name=region_code)
    logs = boto3.client('logs', region_name=region_code)
    cloudwatch = boto3.client('cloudwatch', region_name=region_code)
    s3 = boto3.client('s3', region_name=region_code)
    sqs = boto3.client('sqs', region_name=region_code)
    sns = boto3.client('sns', region_name=region_code)
    ssm = boto3.client('ssm', region_name=region_code)
    kms = boto3.client('kms', region_name=region_code)

    # Define API calls for each service
    services = {
        "EC2": lambda: ec2.describe_instances(),
        "Logs": lambda: logs.describe_log_groups(),
        "CloudWatch": lambda: cloudwatch.list_metrics(),
        "S3": lambda: s3.list_buckets(),
        "SQS": lambda: sqs.list_queues(),
        "SNS": lambda: sns.list_topics(),
        "SSM": lambda: ssm.describe_instance_information(),
        "KMS": lambda: kms.list_keys()
    }

    # Test each service
    for service_name, api_call in services.items():
        test_service(service_name, api_call)