#!/usr/bin/env python
import httplib
import os
import json
import sys
import math
import time
import tempfile
import signal
import datetime
from multiprocessing import Pool

def init_worker():
    signal.signal(signal.SIGINT, signal.SIG_IGN)

def get_client(host=None, raise_errors=False):
    try:
        if host == None:
            return httplib.HTTPSConnection(os.environ['DDSHOST'])
        else:
            return httplib.HTTPSConnection(host)
    except KeyError as err:
        errout = "Please set ENV: {0}\n".format(err)
        if raise_errors:
          raise KeyError(errout)
        else:
          sys.stderr.write(errout)
          exit(1)

def authenticate_agent(raise_errors=False):
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
        if raise_errors:
          raise KeyError("Please set env['AGENT_KEY'] and ENV['USER_KEY']")
        else:
          sys.stderr.write("Please set ENV['AGENT_KEY'] and ENV['USER_KEY']\n")
          exit(1)
    except:
        raise

def get_response_data(client, expected_status):
    resp = client.getresponse()
    if resp.status != expected_status:
      errout = "%s %s\n" % (resp.status,resp.reason)
      sys.stderr.write(errout)
      exit(1)
    return resp.read()

def get_object(client, expected_status,raise_errors=False):
    data = get_response_data(client, expected_status)
    object = json.loads(data)
    if "error" in object:
        if raise_error:
          raise ValueError(data)
        else:
          sys.stderr.write(data)
          sys.stderr.write("\n")
          exit(1)
    return object

class PartialChunkDownloadError(Exception):
    def __init__(self, actual_bytes, expected_bytes, path):
        self.message = "Received too few bytes downloading part of a file. " \
                       "Actual: {} Expected: {} File:{}".format(actual_bytes, expected_bytes, path)
        super(PartialChunkDownloadError, self).__init__(self.message)


class TooLargeChunkDownloadError(Exception):
    def __init__(self, actual_bytes, expected_bytes, path):
        self.message = "Received too many bytes downloading part of a file. " \
                       "Actual: {} Expected: {} File:{}".format(actual_bytes, expected_bytes, path)
        super(TooLargeChunkDownloadError, self).__init__(self.message)

def make_ranges(size):
    bytes_per_chunk = 20 * 1024 * 1024
    if os.environ.has_key("BYTES_PER_CHUNK"):
        bytes_per_chunk = int(os.environ["BYTES_PER_CHUNK"])

    start = 0
    ranges = []
    while size > 0:
        amount = bytes_per_chunk
        if amount > size:
            amount = size
        ranges.append((start, start + amount - 1))
        start += amount
        size -= amount
    return ranges

def download_async(file_id, path, range_start, range_end):
    range_headers = {'Range': 'bytes={}-{}'.format(range_start, range_end)}
    bytes_to_read = range_end - range_start + 1
    seek_amt = range_start
    partial_download_failures = 0
    actual_bytes_read = 0
    success = None
    error = None
    while True:
        try:
            api_token = authenticate_agent(True)

            client = get_client()
            headers = {
              "Authorization": api_token,
              "Accept": "application/json"
            }

            file_info_url = '/api/v1/files/%s/url' % (file_id)
            client.request("GET", file_info_url, None, headers)
            dds_file = get_object(client, 200, True)

            client = get_client(dds_file['host'].replace("https://",""))
            client.request("GET", dds_file['url'], None, range_headers)
            resp = client.getresponse()
            if resp.status != 206:
                raise PartialChunkDownloadError(actual_bytes_read, bytes_to_read, path)
            data = resp.read()

            actual_bytes_read = len(data)
            if actual_bytes_read > bytes_to_read:
                raise TooLargeChunkDownloadError(actual_bytes_read, bytes_to_read, path)
            elif actual_bytes_read < bytes_to_read:
                raise PartialChunkDownloadError(actual_bytes_read, bytes_to_read, path)

            with open(path, 'r+b') as outfile:  # open file for read/write (no truncate)
                outfile.seek(seek_amt)
                outfile.write(data)
            success = "%s bytes %s-%s processed\n" % (str(datetime.datetime.now()), range_start, range_end)
            break
        except (PartialChunkDownloadError, httplib.HTTPException) as err:
            # partial downloads can be due to flaky connections so we should retry a few times
            partial_download_failures += 1
            if partial_download_failures <= 5:
                time.sleep(1)
                # loop will download chunk again
            else:
                error = "%s bytes %s-%s experienced too many partial download failures %s\n" % (str(datetime.datetime.now()), range_start, range_end, str(err))
                break
        except Exception as err:
            error = "%s bytes %s-%s experienced error %s\n" % (str(datetime.datetime.now()), range_start, range_end, str(err))
            break
    return (success, error)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        errout = "usage: %s file_id out\nout must be a path\n" % (sys.argv[0])
        sys.stderr.write(errout)
        exit(1)

    file_id = sys.argv[1]
    file_path = sys.argv[2]

    file_info_url = '/api/v1/files/%s' % (file_id)

    api_token = authenticate_agent()
    client = get_client()
    headers = {
      "Authorization": api_token,
      "Accept": "application/json"
    }
    client.request("GET", file_info_url, None, headers)
    dds_file = get_object(client, 200)
    size = int(dds_file["current_version"]["upload"]["size"])
    ranges = make_ranges(size)
    current_workers = 0
    max_workers = 2
    if os.environ.has_key("DOWNLOAD_WORKERS"):
        max_workers = int(os.environ["DOWNLOAD_WORKERS"])

    with open(file_path, "wb") as outfile:
        if size > 0:
            outfile.seek(size - 1)
            outfile.write(b'\0')

    pool = Pool(processes=max_workers, initializer=init_worker)
    results = []

    try:
        for range_start, range_end in ranges:
            sys.stderr.write("%s submitting bytes %s-%s for processing\n" % (str(datetime.datetime.now()), range_start, range_end))
            results.append(
                pool.apply_async(
                    download_async, 
                    args=(file_id, file_path, range_start, range_end))) 

        for response in results:
            success, error = response.get()
            if success != None:
                sys.stderr.write(success)
            if error != None:
                sys.stderr.write(err)

    except KeyboardInterrupt:
        sys.stderr.write("Caught KeyboardInterrupt, terminating workers\n")
        pool.terminate()
        pool.join()
