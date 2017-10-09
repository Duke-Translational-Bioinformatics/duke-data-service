#!/usr/bin/env python
"""Connect to the Duke Data Service hosted in the url set in ENV['DDSHOST'];
   Authenticate either with a DDS authentication_token (see authenticate_agent.py)
   set in ENV['API_TOKEN'], or using the agent_key set in ENV['AGENT_KEY'], and
   user_key set in ENV['USER_KEY'];
   Get either the metadata (info), or download location (url) of a file by its
   id.

   Exits with nonzero status if DDSHOST, AGENT_KEY, or USER_KEY environment
   variables are not set.
"""
import httplib
import os
import json
import sys

def get_client():
    """create an hhtps connection to the host specified in the DDSHOST environment variable.
       Exits the program with nonzero status if the DDSHOST environment variable is not set.
    """
    try:
        return httplib.HTTPSConnection(os.environ['DDSHOST'])
    except KeyError as err:
        errout = "Please set ENV: {0}\n".format(err)
        sys.stderr.write(errout)
        exit(1)

def authenticate_agent():
    """authenticate the agent using the AGENT_KEY and USER_KEY environment variables.

       Exits the program with a nonzero status if AGENT_KEY or USER_KEY environment
       variables are not set.

       Returns a string authentication_token.
    """
    try:
        agent_key = os.environ['AGENT_KEY']
        user_key = os.environ['USER_KEY']
        swbody = '{"agent_key":"%s","user_key":"%s"}' % (agent_key, user_key)
        swurl = '/api/v1/software_agents/api_token'
        headers = {"Accept": "application/json"}
        client = get_client()
        client.request("POST", swurl, swbody, headers)
        return get_object(client, 201)["api_token"]
    except KeyError:
        sys.stderr.write("Please set ENV['AGENT_KEY'] and ENV['USER_KEY']\n")
        exit(1)
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise

def get_response_data(client, expected_status):
    """gets the response from the https connection, checks the status, and returns
       the response.

       :param client: https connection returned by get_client
       :param expected_status: HTTP response status integer

       Exits the program with nonzero status if the response status does not equal
       the expected_status.

       Returns the string response data.
    """
    resp = client.getresponse()
    if resp.status != expected_status:
        errout = "%s %s\n" % (resp.status, resp.reason)
        sys.stderr.write(errout)
        exit(1)

    return resp.read()

def get_object(client, expected_status):
    """calls get_response_data and serializes the response JSON into an object.
       see get_response_data for params

       If the serialized object contains a key "errror", the response string is
       written to stderr and the program is exited with nonzero status.

       returns object
    """
    data = get_response_data(client, expected_status)
    dds_object = json.loads(data)
    if "error" in dds_object:
        sys.stderr.write(data)
        sys.stderr.write("\n")
        exit(1)

    return dds_object

USAGE = """usage: %s req file_id
req can be one of:
info: get the file info
url: get the download url
""" % (sys.argv[0])

if len(sys.argv) < 3:
    sys.stderr.write(USAGE)
    exit(1)

REQ_TYPE = sys.argv[1]
FILE_ID = sys.argv[2]

if REQ_TYPE == 'info':
    FILE_INFO_URL = '/api/v1/files/%s' % (FILE_ID)
elif REQ_TYPE == 'url':
    FILE_INFO_URL = '/api/v1/files/%s/url' % (FILE_ID)
else:
    sys.stderr.write(USAGE)
    exit(1)

API_TOKEN = None
if os.environ.has_key('API_TOKEN'):
    API_TOKEN = os.environ['API_TOKEN']
else:
    #exchange software_agent for API_TOKEN
    API_TOKEN = authenticate_agent()

CLIENT = get_client()
HEADERS = {
    "Authorization": API_TOKEN,
    "Accept": "application/json"
}
CLIENT.request("GET", FILE_INFO_URL, None, HEADERS)
DDS_FILE = get_object(CLIENT, 200)
print json.dumps(DDS_FILE)
