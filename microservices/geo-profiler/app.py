import json
import boto3
import datetime
import os

index = os.environ['ES_index']

def lambda_handler(event, context):
    
    parsed_json = json.dumps(event)
    input_terms = json.loads(parsed_json)
    
    search_query = input_terms["search_query"]
    
    dynamodb = boto3.resource('dynamodb')

    patient_postcode_lat = search_query['subject']['address']['position']['latitude']
    patient_postcode_lng = search_query['subject']['address']['position']['longitude']
    
    geo_query = {
        "query": {
            "bool": {
            "must": {
                "match_all": {}
            },
            "filter": {
                "geo_shape": {
                "geographic_boundary": {
                    "relation": "intersects",
                    "shape": {
                    "coordinates": [
                        patient_postcode_lng,
                        patient_postcode_lat
                    ],
                    "type": "point"
                    }
                }
                }
            }
            }
        }
    }

    resp = {
        "search_index": index,
        "search_query": geo_query
    }
    
    json_response = json.dumps(resp)

    return json_response