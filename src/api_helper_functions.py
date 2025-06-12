import requests

def get_api(batch_id, api_link, auth_key):
    full_api_link = api_link + batch_id
    authorization_key = auth_key

    get_json = requests.get(
        full_api_link,
        headers={"Authorization" : authorization_key}
        ).json() # Turns request into a json file
    # print("json: {}".format(get_json))
    return get_json