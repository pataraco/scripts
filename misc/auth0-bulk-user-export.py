# import http.client
import urllib3
import json
import time

# Auth0 Tenant: raco-test
# Auth0 > Applications > Settings > Domain
AUTH0_DOMAIN = "raco-test.us.auth0.com"
CLIENT_ID = "XJrzY5ml0JmBgU"
CLIENT_SECRET = "fjBM8gPywVcQiy9LJs6"

# API Paths
# Auth0 > Applications > APIs > Autho Management API > General Settings > Identifier
AUDIENCE = f"https://{AUTH0_DOMAIN}/api/v2/"
AUTH_PATH = "oauth/token"
CONNECTIONS_PATH = "api/v2/connections"
USER_EXPORTS_PATH = "api/v2/jobs/users-exports"
JOB_STATUS_PATH = "api/v2/jobs/{job_id}"

DB_CONNECTION_NAME = "Username-Password-Authentication"
SLEEP_TIME = 1  # seconds to wait in between checking for export job status
LOCAL_EXPORT_FILE = f"{AUTH0_DOMAIN}.ndjson.gz"  # where to save the downloaded file

# need a PoolManager instance to make requests
http = urllib3.PoolManager()

#
# get bearer token
#
auth_url = f"https://{AUTH0_DOMAIN}/{AUTH_PATH}"
# print("auth_url:", type(auth_url))
# print(auth_url)
headers = {"Content-Type": "application/json"}
body = json.dumps({  # body must be a string
    "client_id": CLIENT_ID,
    "client_secret": CLIENT_SECRET,
    "audience": AUDIENCE,
    "grant_type": "client_credentials",
}).encode("utf-8")
# print("body", type(body))
# print(body)
request = http.request("POST", auth_url, headers=headers, body=body)
# print("request:", type(request))
# print(request)
response = json.loads(request.data.decode("utf-8"))
# print("request_dict:", type(request_dict))
# print(request_dict)
bearer_access_token = response.get("access_token")
#     print("got the same token")

#
# get connection id
#
connections_url = f"https://{AUTH0_DOMAIN}/{CONNECTIONS_PATH}"
headers = {"authorization": f"bearer {bearer_access_token}"}
fields = {"name": DB_CONNECTION_NAME}
request = http.request("get", connections_url, headers=headers, fields=fields)
response = json.loads(request.data.decode("utf-8"))
connection_id = response[0].get("id")

#
# initiate bulk user export job
#
user_exports_url = f"https://{AUTH0_DOMAIN}/{USER_EXPORTS_PATH}"
headers = {
    "authorization": f"Bearer {bearer_access_token}",
    "content-type": "application/json",
}

# get the ndjson formatted export
# Auth0's export files use the ndjson format due to the large size of the
# export files, while the import functionality expects a JSON file.
body = json.dumps({  # body must be a string
    "connection_id": connection_id,
    "format": "json",
}).encode("utf-8")
request = http.request("POST", user_exports_url, headers=headers, body=body)
response = json.loads(request.data.decode("utf-8"))
job_id = response.get("id")
# print(f"job_id: {job_id}")

#
# get job status
#
# wait for a bit
print(f"sleeping for {SLEEP_TIME} second(s)")
time.sleep(SLEEP_TIME)

job_status_url = f"https://{AUTH0_DOMAIN}/{JOB_STATUS_PATH}".format(**locals())
headers = {"authorization": f"Bearer {bearer_access_token}"}
request = http.request("GET", job_status_url, headers=headers)
response = json.loads(request.data.decode("utf-8"))
# print(response)
status = response.get("status")
# print(f"status: {status}")
while status != "completed":
    # wait for a bit more
    print(f"sleeping for {SLEEP_TIME} seconds")
    time.sleep(SLEEP_TIME)
    request = http.request("GET", job_status_url, headers=headers)
    response = json.loads(request.data.decode("utf-8"))
    # print(response)
    status = response.get("status")
    # print(f"status: {status}")

#
# get generated export file
#
exported_file_location = response.get("location")
# print(f"exported file location: {exported_file_location}")
request = http.request('GET', exported_file_location, preload_content=False)
with open(LOCAL_EXPORT_FILE, 'wb') as out:
    while True:
        #  data = request.read(chunk_size)
        data = request.read()
        if not data:
            break
        out.write(data)
request.release_conn()
