#!/usr/bin/env python
import httplib
import os
import json
import sys

def get_client():
    try:
        return httplib.HTTPSConnection(os.environ['DDSHOST'])
    except KeyError as err:
        errout = "Please set ENV: {0}\n".format(err)
        sys.stderr.write(errout)
        exit(1)

def authenticate_agent():
    try:
        agent_key = os.environ['AGENT_KEY']
        user_key = os.environ['USER_KEY']
        swbody = '{"agent_key":"%s","user_key":"%s"}' % (agent_key,user_key)
        swurl = '/api/v1/software_agents/api_token'
        headers = {"Accept": "application/json"}
        client = get_client()
        client.request("POST", swurl, swbody, headers)
        return get_object(client, 201)["api_token"]
    except KeyError as err:
        sys.stderr.write("Please set ENV['AGENT_KEY'] and ENV['USER_KEY']\n")
        exit(1)
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise

def get_response_data(client, expected_status):
    resp = client.getresponse()
    if resp.status != expected_status:
      errout = "%s %s\n" % (resp.status,resp.reason)
      sys.stderr.write(errout)
      exit(1)

    return resp.read()

def get_object(client, expected_status):
    data = get_response_data(client, expected_status)
    object = json.loads(data)
    if "error" in object:
        sys.stderr.write(data)
        sys.stderr.write("\n")
        exit(1)

    return object

if len(sys.argv) < 3:
    errout = "usage: %s req file_id\nreq can be one of:\n  info: get the file info\n  url: get the download url\n" % (sys.argv[0])
    sys.stderr.write(errout)
    exit(1)

req = sys.argv[1]
file_id = sys.argv[2]

api_token = None
if os.environ.has_key('API_TOKEN'):
    api_token = os.environ['API_TOKEN']
else:
    #exchange software_agent for api_token
    api_token = authenticate_agent()

if req == 'info':
    file_info_url = '/api/v1/files/%s' % (file_id)
elif req == 'url':
    file_info_url = '/api/v1/files/%s/url' % (file_id)
else:
    errout = "usage: %s req file_id\nreq can be one of:\n  info: get the file info\n  url: get the download url\n" % (sys.argv[0])
    sys.stderr.write(errout)
    exit(1)

client = get_client()
headers = {
  "Authorization": api_token,
  "Accept": "application/json"
}
client.request("GET", file_info_url, None, headers)
dds_file = get_object(client, 200)
print json.dumps(dds_file)
