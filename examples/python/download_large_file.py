#!/usr/bin/env python
"""Connect to the Duke Data Service hosted in the url set in ENV['DDSHOST'];
   Authenticate either with a DDS authentication_token (see authenticate_agent.py)
   set in ENV['API_TOKEN'], or using the agent_key set in ENV['AGENT_KEY'], and
   user_key set in ENV['USER_KEY'];
   Download a large file by its id into a specified output file. Downloads
   multiple parts of the file at the same time in parallel.

   Exits with nonzero status if DDSHOST, AGENT_KEY, or USER_KEY environment
   variables are not set.
"""
import httplib
import os
import json
import sys
import time
import signal
import datetime
from multiprocessing import Pool

def init_worker():
    """sets a signal processeor to ignore SIGINT"""
    signal.signal(signal.SIGINT, signal.SIG_IGN)

def get_client(host=None, raise_errors=False):
    """create an hhtps connection to the host specified in the DDSHOST environment variable.
       Exits the program with nonzero status if the DDSHOST environment variable is not set.
    """
    try:
        if host is None:
            return httplib.HTTPSConnection(os.environ['DDSHOST'])
        return httplib.HTTPSConnection(host)
    except KeyError as err:
        errout = "Please set ENV: {0}\n".format(err)
        if raise_errors:
            raise KeyError(errout)
        else:
            sys.stderr.write(errout)
            exit(1)

def authenticate_agent(raise_errors=False):
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
        if raise_errors:
            raise KeyError("Please set env['AGENT_KEY'] and ENV['USER_KEY']")
        else:
            sys.stderr.write("Please set ENV['AGENT_KEY'] and ENV['USER_KEY']\n")
            exit(1)
    except:
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

def get_object(client, expected_status, raise_errors=False):
    """calls get_response_data and serializes the response JSON into an object.
       see get_response_data for params

       If the serialized object contains a key "errror", the response string is
       written to stderr and the program is exited with nonzero status.

       returns object
    """
    data = get_response_data(client, expected_status)
    dds_object = json.loads(data)
    if "error" in dds_object:
        if raise_errors:
            raise ValueError(data)
        else:
            sys.stderr.write(data)
            sys.stderr.write("\n")
            exit(1)
    return dds_object

class PartialChunkDownloadError(Exception):
    """An Exception to be thrown when only part of a chunk is
    downloaded.
    """
    def __init__(self, actual_bytes, expected_bytes, path):
        """initializes a ParticalChunkDownloadError with actual_bytes
        expected_bytes, and path
        """
        self.message = "Received too few bytes downloading part of a file. " \
                       "Actual: {} Expected: {} File:{}".format(actual_bytes, expected_bytes, path)
        super(PartialChunkDownloadError, self).__init__(self.message)


class TooLargeChunkDownloadError(Exception):
    """An Exception to be thrown if more than the expected amount of data is
    downloaded for a chunk.
    """
    def __init__(self, actual_bytes, expected_bytes, path):
        """initializes a TooLargeChunkDownloadError with actual_bytes
        expected_bytes, and path
        """
        self.message = "Received too many bytes downloading part of a file. " \
                       "Actual: {} Expected: {} File:{}".format(actual_bytes, expected_bytes, path)
        super(TooLargeChunkDownloadError, self).__init__(self.message)

def make_ranges(size):
    """takes a size and returns a list of start and stop offsets
    bytes_per_chunk defaults to 20MB, unless overriden by the
    BYTES_PER_CHUNK environment variable.
    """
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
    """authenticates with the api_token, and attempts to download the
    specified file_id, to the offset in the file at path starting from
    range_start.

    Attempts to download the same chunk up to 5 times before registering
    an error, and quitting.

    returns a list (error, success), which are either None, or a string
    with information about the success or error.
    """
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

            client = get_client(dds_file['host'].replace("https://", ""))
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
            success = "%s bytes %s-%s processed\n" % (
                str(datetime.datetime.now()),
                range_start,
                range_end
            )
            break
        except (PartialChunkDownloadError, httplib.HTTPException) as err:
            # partial downloads can be due to flaky connections so we should retry a few times
            partial_download_failures += 1
            if partial_download_failures <= 5:
                time.sleep(1)
                # loop will download chunk again
            else:
                error = "%s bytes %s-%s experienced too many partial download failures %s\n" % (
                    str(datetime.datetime.now()),
                    range_start, range_end,
                    str(err)
                )
                break
        except Exception as err:
            error = "%s bytes %s-%s experienced error %s\n" % (
                str(datetime.datetime.now()),
                range_start,
                range_end,
                str(err)
            )
            break
    return (success, error)

if __name__ == "__main__":
    USAGE = "usage: %s file_id out\nout must be a path\n" % (sys.argv[0])
    if len(sys.argv) < 3:
        sys.stderr.write(USAGE)
        exit(1)

    FILE_ID = sys.argv[1]
    FILE_PATH = sys.argv[2]

    FILE_INFO_URL = '/api/v1/files/%s' % (FILE_ID)

    API_TOKEN = authenticate_agent()
    CLIENT = get_client()
    HEADERS = {
        "Authorization": API_TOKEN,
        "Accept": "application/json"
    }
    CLIENT.request("GET", FILE_INFO_URL, None, HEADERS)
    DDS_FILE = get_object(CLIENT, 200)
    SIZE = int(DDS_FILE["current_version"]["upload"]["size"])
    RANGES = make_ranges(SIZE)
    CURRENT_WORKERS = 0
    MAX_WORKERS = 2
    if os.environ.has_key("DOWNLOAD_WORKERS"):
        MAX_WORKERS = int(os.environ["DOWNLOAD_WORKERS"])

    with open(FILE_PATH, "wb") as OUTFILE:
        if SIZE > 0:
            OUTFILE.seek(SIZE - 1)
            OUTFILE.write(b'\0')

    POOL = Pool(processes=MAX_WORKERS, initializer=init_worker)
    RESULTS = []

    try:
        for RANGE_START, RANGE_END in RANGES:
            sys.stderr.write("%s submitting bytes %s-%s for processing\n" % (
                str(datetime.datetime.now()), RANGE_START, RANGE_END))
            RESULTS.append(
                POOL.apply_async(
                    download_async,
                    args=(FILE_ID, FILE_PATH, RANGE_START, RANGE_END)))

        for RESPONSE in RESULTS:
            SUCCESS, ERROR = RESPONSE.get()
            if SUCCESS != None:
                sys.stderr.write(SUCCESS)
            if ERROR != None:
                sys.stderr.write(ERROR)

    except KeyboardInterrupt:
        sys.stderr.write("Caught KeyboardInterrupt, terminating workers\n")
        POOL.terminate()
        POOL.join()
