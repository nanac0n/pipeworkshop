import json
import boto3
import gzip
from io import BytesIO
import os
from botocore.awsrequest import AWSRequest
from botocore.auth import SigV4Auth
from botocore.httpsession import URLLib3Session

def lambda_handler(event, context):
    s3_client = boto3.client('s3')
    region = os.environ['AWS_REGION']  # AWS 리전을 환경 변수에서 가져옴
    service = 'es'

    # S3에서 로그 데이터 가져오기
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        response = s3_client.get_object(Bucket=bucket, Key=key)
        
        with gzip.GzipFile(fileobj=BytesIO(response['Body'].read())) as gzipfile:
            for line in gzipfile:
                log_entry = json.loads(line.decode('utf-8').strip())
                send_to_opensearch(log_entry, region, service)

def send_to_opensearch(log_data, region, service):
    opensearch_endpoint = os.environ['OPENSEARCH_ENDPOINT']  # OpenSearch 엔드포인트를 환경 변수에서 가져옴
    opensearch_index = "guardduty-logs"
    url = f"https://{opensearch_endpoint}/{opensearch_index}/_doc"

    # AWS 서명 생성
    credentials = boto3.Session().get_credentials()
    request = AWSRequest(method="POST", url=url, data=json.dumps(log_data), headers={"Content-Type": "application/json"})
    SigV4Auth(credentials, service, region).add_auth(request)

    # 요청 전송
    session = URLLib3Session()
    response = session.send(request.prepare())

    if response.status_code != 201:
        print(f"Failed to send data to OpenSearch: Status code {response.status_code}, Response: {response.text}")
    else:
        print("Data sent to OpenSearch successfully.")
