import logging
import requests
from requests.adapters import HTTPAdapter
from urllib.parse import urlparse
import dns.resolver
import socket

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CustomAdapter(HTTPAdapter):
    def send(self, request, **kwargs):
        logger.info(f"Host: {urlparse(request.url).netloc}")
        logger.info(f"Full request line: {request.method} {request.url} HTTP/1.1")
        return super().send(request, **kwargs)

def log_all_dns_requests():
    def custom_getaddrinfo(*args, **kwargs):
        host = args[0]
        logger.info(f"DNS Query: {host}")
        result = original_getaddrinfo(*args, **kwargs)
        logger.info(f"DNS Response: {host} -> {[r[4][0] for r in result]}")
        return result

    original_getaddrinfo = socket.getaddrinfo
    socket.getaddrinfo = custom_getaddrinfo

def test_s3_url_styles(bucket_name, region_code, key_name):
    # Test virtual-hosted-style URL
    virtual_hosted_url = f"https://{bucket_name}.s3.{region_code}.amazonaws.com/{key_name}"
    logger.info(f"\nTesting virtual-hosted-style URL: {virtual_hosted_url}")
    make_request(virtual_hosted_url)

    # Test path-style URL
    path_style_url = f"https://s3.{region_code}.amazonaws.com/{bucket_name}/{key_name}"
    logger.info(f"\nTesting path-style URL: {path_style_url}")
    make_request(path_style_url)

def make_request(url):
    try:
        # Create a session with our custom adapter
        session = requests.Session()
        session.mount('https://', CustomAdapter())
        # Make the request
        response = session.get(url)
        logger.info("Response content:")
        print(response.text)

    except Exception as e:
        logger.error(f"Error making request: {e}")

if __name__ == "__main__":
    log_all_dns_requests()  # Enable DNS logging

    # Default settings
    default_bucket_name = "producer-public-bucket-r1l4"
    default_region_code = "us-east-1"
    default_key_name = "payload.sh"

    # Ask user for input
    use_default = input("Do you want to use default settings? (yes/no): ").lower().strip()

    if use_default == 'yes':
        bucket_name = default_bucket_name
        region_code = default_region_code
        key_name = default_key_name
    else:
        bucket_name = input(f"Enter bucket name (default: {default_bucket_name}): ").strip() or default_bucket_name
        region_code = input(f"Enter region code (default: {default_region_code}): ").strip() or default_region_code
        key_name = input(f"Enter key name (default: {default_key_name}): ").strip() or default_key_name

    print(f"\nUsing the following settings:")
    print(f"Bucket Name: {bucket_name}")
    print(f"Region Code: {region_code}")
    print(f"Key Name: {key_name}\n")


    test_s3_url_styles(bucket_name, region_code, key_name)