import json
import os
import boto3
from boto3.dynamodb.types import TypeDeserializer
import requests
from requests_aws4auth import AWS4Auth

region = os.environ['ES_region'] 
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

host = os.environ['ES_domain']
index = os.environ['ES_index']
type = '_doc'
url = 'https://' + host + '/' + index + '/' + type + '/'

headers = { "Content-Type": "application/json" }

def lambda_handler(event, context):

    count = 0
    for record in event['Records']:
        id = record['dynamodb']['Keys']['id']['S']

        if record['eventName'] == 'REMOVE':
            r = requests.delete(url + id, auth=awsauth)
        else:
            document = ddb_deserialize(record['dynamodb']['NewImage'])
            print(document)
            r = requests.put(url + id, auth=awsauth, json=document, headers=headers)
        count += 1
    return str(count) + ' records processed.'



def ddb_deserialize(r, type_deserializer = TypeDeserializer()):
    return type_deserializer.deserialize({"M": r})


