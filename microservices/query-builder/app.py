import json
import os
import boto3
import datetime
from boto3.dynamodb.conditions import Key

index = os.environ['ES_index']

def lambda_handler(event, context):
    
    parsed_json = json.dumps(event)
    input = json.loads(parsed_json)
    
    search_query = input['search_query']
    search_profile = input['query_modifiers']['search_profile']
    geo_profiles = input['query_modifiers']['geo_profiles']

    base_query = construct_base_query(search_query)

    print(base_query)

    profiled_query = profile_query(base_query, search_profile, geo_profiles)

    print(profiled_query)
        
   
    resp = {
        "search_index": index,
        "search_query": profiled_query
    }
    
    json_response = json.dumps(resp)

    return  json_response



def construct_base_query(consumer_query):

    #PLEASE CONSIDER: IN FUTURE THE MAPPING OF THE VARIABLES NEEDED FOR THE DOS SEARCH
    #COULD BE ABSTRACTED AWAY INTO A SEARCH PROFILE TO ADD FLEXIBILITY TO THE INPUT
    #FOR NOW, ITS HARD CODED HERE:

    requested_activity = consumer_query['activity']['detail']['code']['code']
    chief_complaint = consumer_query['addresses']['code']
    requested_acuity = consumer_query['activity']['detail']['scheduledPeriod']['acuity']
    requested_location = consumer_query['activity']['detail']['location']['position']

    patient_age_range= consumer_query['subject']['birthDate']
    patient_gender = consumer_query['subject']['gender']

    query_datetime = datetime.datetime.now()
    query_day = query_datetime.strftime("%a")

    # FOR RANGE QUERY, WE NEED THE TIME IN AN EASILY COMPARABLE NUMBER, SO CONSIDER AS A 24HR DECIMAL 
    query_time_decimal = query_datetime.hour + ((query_datetime.minute * 60 + query_datetime.second)/3600)

 
    #BUILD THE BASIC ELASTIC QUERY
    base_query = {"query": {
        "bool" : {
            "must": 
                [
                    {"match": {"referralProfiles.activitiesOffered": requested_activity}},
                    {"match": {"referralProfiles.acuities": requested_acuity}},
                    {"match": {"referralProfiles.referralSpecificProperties.eligibility.gender": patient_gender}},
                    {"match" : {"referralProfiles.referralSpecificProperties.eligibility.ageRange": patient_age_range}},
                    {"match" : {"referralProfiles.referralSpecificProperties.availableTime.daysOfWeek": query_day}},
                    {"bool": {
                        "should": 
                            [
                                {"match" : {"referralProfiles.referralSpecificProperties.availableTime.allDay": True}},
                                {"bool":
                                    {
                                        "must": 
                                            [
                                                { "range":
                                                    { "referralProfiles.referralSpecificProperties.availableTime.openingTime": {
                                                        "gte": query_time_decimal,
                                                        "lte": 0
                                                    }
                                                    }
                                                },
                                                { "range":
                                                    { "referralProfiles.referralSpecificProperties.availableTime.closingTime": {
                                                        "gte": 0,
                                                        "lte": query_time_decimal
                                                    }
                                                    }
                                                }
                                            ]
                                    }
                                }
                            ]
                        }
                    }
                ]
        }
    }}

    return base_query



def profile_query(base_query, search_profile, geo_profiles):

    profiled_query = base_query

    # GEO-PROFILE BASED LOGIC
    if not geo_profiles:
        print('No relevant geo-sorting strategy is associated with this postcode.')
    else:
        print('Selecting highest priority geo-profile')
        #PERFORM SEQUENTIAL SELECTION THROUGH LADS, LDAS, ETC.

        ranking_strategy = determine_ranking_strategy(geo_profiles, "LAD")
        if not ranking_strategy:
            ranking_strategy = determine_ranking_strategy(geo_profiles, "LDA")
        if not ranking_strategy:
            ranking_strategy = determine_ranking_strategy(geo_profiles, "CCG")


    # SEARCH PROFILE BASED LOGIC
    if search_profile['exclusions']:
        profiled_query['query']['bool']['must_not'] = []
        for exclusion in search_profile['exclusions']:
            if not exclusion:
                continue
            profiled_query['query']['bool']['must_not'].append(json.loads(exclusion))

    if search_profile['sorters'] or ranking_strategy:
        profiled_query['sort'] = []
        for sorter in search_profile['sorters']:
            if not sorter:
                continue
            profiled_query['sort'].append(json.loads(sorter))
        if ranking_strategy:
            profiled_query['sort'].append(json.loads(ranking_strategy))  

    if search_profile['redactions']:
        profiled_query['_source'] = {'excludes' : [] }
        for redaction in search_profile['redactions']:
            if not redaction:
                continue
            profiled_query['_source']['excludes'].append(redaction)

    #TBC IF WE HAVE A USE CASE FOR FORMATTERS, AS THIS MIGHT NOT BE NEEDED

    return profiled_query



def determine_ranking_strategy(geo_profiles, profile_type):
    highest_priority_geo_profile = next((geo_profile for geo_profile in geo_profiles if geo_profile['_source']['type'] == profile_type), None)

    if not highest_priority_geo_profile:
        return False
    else:
        return highest_priority_geo_profile['_source']['ranking_strategy']
