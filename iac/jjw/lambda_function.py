import os
import boto3
from elasticsearch import Elasticsearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

def lambda_handler(event, context):
    host = os.environ['ES_ENDPOINT']
    index_pattern = 'aws-waf-logs-*' # 인덱스 패턴 이름을 'aws-waf-logs-*'로 설정

    region = 'ap-northeast-2'
    service = 'es'
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

    es = Elasticsearch(
        hosts = [{'host': host, 'port': 443}],
        http_auth = awsauth,
        use_ssl = True,
        verify_certs = True,
        connection_class = RequestsHttpConnection
    )

    index_pattern_id = ".kibana/doc/index-pattern:" + index_pattern
    if not es.exists(index=index_pattern_id):
        doc = {
            "title": index_pattern,
            "timeFieldName": "timestamp"
        }
        es.index(index=index_pattern_id, body=doc)
        message = 'Index pattern created successfully'
    else:
        message = 'Index pattern already exists'

    return {
        'statusCode': 200,
        'body': message
    }