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
        token_info = get_object(client, 201)
    except KeyError as err:
        sys.stderr.write("Please set ENV['AGENT_KEY'] and ENV['USER_KEY']\n")
        exit(1)
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise
    return token_info["api_token"]

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

#exchange software_agent for api_token
sys.stdout.write(authenticate_agent())
