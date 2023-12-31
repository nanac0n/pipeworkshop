import json
import boto3
import base64
from datetime import datetime, timedelta
from botocore.awsrequest import AWSRequest
from botocore.auth import SigV4Auth
from botocore.httpsession import URLLib3Session

def lambda_handler(event, context):
    opensearch_endpoint = os.environ['OPENSEARCH_ENDPOINT']
    region = os.environ['AWS_REGION']

    for record in event['records']:
        message = json.loads(base64.b64decode(record['data']).decode('utf-8'))

        # 시간 정규화
        timestamp = message['timestamp']
        timestamp /= 1000
        timestamp = datetime.utcfromtimestamp(timestamp) + timedelta(hours=9)
        message['timestamp'] = timestamp.strftime('%Y-%m-%dT%H:%M:%S.%f+0900')

        # 사용자 정의 처리
        message['CHECK_BLOCK'] = check_block(message.get('action', ''))
        message['sqli'] = check_sqli(message.get('terminatingRuleId', ''))

        # OpenSearch로 데이터 전송
        send_to_opensearch(message, opensearch_endpoint, region)

    return {"records": event['records']}

def send_to_opensearch(log_data, endpoint, region):
    url = f"https://{endpoint}/cloudwatch-logs/_doc"
    credentials = boto3.Session().get_credentials()
    request = AWSRequest(method="POST", url=url, data=json.dumps(log_data), headers={"Content-Type": "application/json"})
    SigV4Auth(credentials, 'es', region).add_auth(request)
    session = URLLib3Session()
    response = session.send(request.prepare())

    if response.status_code != 201:
        print(f"Failed to send data to OpenSearch: {response.text}")

def check_block(action):
    return 1 if "BLOCK" in action else 0

def check_sqli(terminatingRuleId):
    return 1 if "SQLi" in terminatingRuleId else 0
