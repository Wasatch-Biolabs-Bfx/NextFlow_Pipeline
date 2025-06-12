from api_helper_functions import get_api
import argparse

# Function that parses the get_api() get_json into a list of lists where each list is sample info
def parse_json(json_string):
    parsed_json = []

    for entry in json_string['samples']:
        # test_type = entry['testType']
        test_type = entry['protocolType']

        barcode = entry['barcode']
        if barcode != None and int(barcode)<10: # making sure single digit barcodes actually are two digits
            barcode="0"+str(barcode)
        
        julian_id = entry['julianId']
        
        # make sure there are no spaces or periods in the req number
        req_number = entry["requisitionNumber"].replace(" ", "_").replace(".", "_")
        
        parsed_json.append([test_type, str(barcode), str(julian_id), str(req_number)])

    return(parsed_json)

# Function that writes the parsed_json to a tsv file 
def write_tsv(parsed_json, batch_id):
    output_tsv = f"{batch_id}.tsv"
    with open(output_tsv, 'w') as tsv_file:
        for item in parsed_json:
            tsv_file.write('\t'.join(item) + '\n')

if __name__ == '__main__':
    # set up parser
    parser = argparse.ArgumentParser(description="Script to run API get requests")
    parser.add_argument('--batch_id', type=str, help="The batch name we want to get information about (e.g. 230929-A)", required=True)
    parser.add_argument('--api_link', type=str, help="API link URL", required=True)
    parser.add_argument('--auth_key', type=str, help="API authorization key", required=True)

    args = parser.parse_args()

    # get request
    get_json=get_api(batch_id=args.batch_id, api_link=args.api_link, auth_key=args.auth_key)
    print(get_json)
    parsed_json = parse_json(get_json)

    # write parsed json
    write_tsv(parsed_json, args.batch_id)