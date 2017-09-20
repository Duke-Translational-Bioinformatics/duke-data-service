#!/usr/bin/env python
import httplib
import os
import json
import sys

def get_client(host=None):
    try:
        if host == None:
            return httplib.HTTPSConnection(os.environ['DDSHOST'])
        else:
            return httplib.HTTPSConnection(host)
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
    errout = "usage: %s file_id out\nout can be a path, or - for stdout\n" % (sys.argv[0])
    sys.stderr.write(errout)
    exit(1)

file_id = sys.argv[1]
if sys.argv[2] == '-':
  out = sys.stdout
else:
  out = open(sys.argv[2], 'w')

api_token = None
try:
    api_token = os.environ['API_TOKEN']
except KeyError:
    #exchange software_agent for api_token
    api_token = authenticate_agent()

file_info_url = '/api/v1/files/%s/url' % (file_id)

client = get_client()
headers = {
  "Authorization": api_token,
  "Accept": "application/json"
}
client.request("GET", file_info_url, None, headers)
dds_file = get_object(client, 200)

client = get_client(dds_file['host'].replace("https://",""))
client.request("GET", dds_file['url'])
data  = get_response_data(client, 200)
out.write(data)
out.close
