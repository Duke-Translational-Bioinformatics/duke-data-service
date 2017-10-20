#!/usr/bin/env python
"""Connect to the Duke Data Service hosted in the url set in ENV['DDSHOST'],
   and get an authentication_token to the Duke Data Service using an agent_key
   set in ENV['AGENT_KEY'], and user_key set in ENV['USER_KEY'].

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
        token_info = get_object(client, 201)
    except KeyError:
        sys.stderr.write("Please set ENV['AGENT_KEY'] and ENV['USER_KEY']\n")
        exit(1)
    except:
        print("Unexpected error:", sys.exc_info()[0])
        raise
    return token_info["api_token"]

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

#exchange software_agent for api_token
sys.stdout.write(authenticate_agent())
