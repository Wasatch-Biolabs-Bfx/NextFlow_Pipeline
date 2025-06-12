import sys
import json
from api_helper_functions import get_api
import argparse
import requests

# Function that will use the get_json() response to format the POST json with the required samples + AWS locations
def post_json_formatter(parsed_json, batch_id):
    post_json = {
        "batchName": batch_id,
        "qcReportS3Key": batch_id + "/" + f"{batch_id}_run_report.html",
        "samples": []
    }

    print(parsed_json)
    for sample in parsed_json["samples"]:
        julian_id = sample["julianId"]
        req_number = sample["requisitionNumber"]
        req_number = req_number.replace(" ", "_") # make sure there are no spaces in the req number
        raw_data_url = batch_id + "/" + f"{req_number}_{julian_id}" + "/" + f"{req_number}_{julian_id}.tar"
        report_url = batch_id + "/" + f"{req_number}_{julian_id}" + "/" + f"{req_number}_{julian_id}_alignment_stats.txt" # changed here
        
        sample_info = {
            "julianId": julian_id,
            "rawDataS3Key": raw_data_url,
            "resultsS3Key": report_url
        }
        
        post_json["samples"].append(sample_info)

    print(post_json)
    return post_json

# Function that uses the post_json_formatter() response and POST's it to the API
def post_api(api_link_post,auth_key,post_json_str):
    # api_link_post = api_link
    authorization_key = auth_key
    res=requests.post(api_link_post,
        headers = {"Authorization" : authorization_key},
        json = post_json_str)
    print(res)

if __name__ == '__main__':
    # set up parser
    parser = argparse.ArgumentParser(description="Script to run API get requests")
    parser.add_argument('--batch_id', type=str, help="The batch name we want to get information about (e.g. 230929-A)", required=True)
    parser.add_argument('--api_link_get', type=str, help="API link for GET request", required=True)
    parser.add_argument('--api_link_post', type=str, help="API link for POST request", required=True)
    parser.add_argument('--auth_key', type=str, help="API authorization key", required=True)

    args = parser.parse_args()

    # post request
    get_json = get_api(batch_id=args.batch_id, api_link=args.api_link_get, auth_key=args.auth_key)
    post_json = post_json_formatter(parsed_json=get_json, batch_id=args.batch_id)
    post_api(api_link_post=args.api_link_post,auth_key=args.auth_key,post_json_str=post_json)