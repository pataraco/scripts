# import http.client
import urllib3
import json
import time

# Auth0 Tenant: raco-test
# Auth0 > Applications > Settings > Domain
AUTH0_DOMAIN = "raco-test.us.auth0.com"
CLIENT_ID = "XJrzY5ml0JmBgU"
CLIENT_SECRET = "fjBM8gPywVcQiy9LJs6"
# Auth0 > Authentication > Database > Username-Password-Authentication > Identifier
# CONNECTION_ID = "co_o0ew77O"

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

# AUTH_URL = 'https://raco-test.us.auth0.com/oauth/token'
# AUTH_URL = 'raco-test.us.auth0.com/oauth/token'

# need a PoolManager instance to make requests
http = urllib3.PoolManager()

# conn = http.client.HTTPSConnection(AUTH0_DOMAIN)
#
# get bearer token
#
# headers = {"content-type": "application/json"}
# body = f'{{"client_id": "{CLIENT_ID}", "client_secret": "{CLIENT_SECRET}", "audience": "{AUDIENCE}", "grant_type": "client_credentials"}}'
# print("body", type(body))
# print(body)

body_dict = {
    "client_id": CLIENT_ID,
    "client_secret": CLIENT_SECRET,
    "audience": AUDIENCE,
    "grant_type": "client_credentials",
}
# body must be a string
body = json.dumps(body_dict)
headers = {"content-type": "application/json"}
data = body_dict

# print("body", type(body))
# print(body)

# conn.request("POST", f"/{AUTH_PATH}", body, headers)
# conn.request("POST", f"/{AUTH_PATH}", body, headers)
# response = json.loads(conn.getresponse().read().decode("utf-8"))
# bearer_access_token_old = response.get("access_token")
# print("response:", type(response))
# print(response)

# try urllib3
auth_url = f"https://{AUTH0_DOMAIN}/{AUTH_PATH}"
headers = {"Content-Type": "application/json"}
# encoded_body = json.dumps(body_dict).encode("utf-8")
body = json.dumps({
    "client_id": CLIENT_ID,
    "client_secret": CLIENT_SECRET,
    "audience": AUDIENCE,
    "grant_type": "client_credentials",
}).encode("utf-8")
# print("auth_url:", type(auth_url))
# print(auth_url)
# request = http.request("POST", auth_url, headers=headers, body=encoded_body)
# request = http.request("POST", auth_url, headers=headers, body=body)
request = http.request("POST", auth_url, headers=headers, body=body)
# print("request:", type(request))
# print(request)
# request_dict = json.loads(request.data.decode("utf-8"))
response = json.loads(request.data.decode("utf-8"))
# print("request_dict:", type(request_dict))
# print(request_dict)
bearer_access_token = response.get("access_token")
# if bearer_access_token == bearer_access_token_old:
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

# res = conn.getresponse()
# data = res.read()
# print(data.decode("utf-8"))
# data_str = data.decode("utf-8")
# print("data_str", type(data_str))
# print(data_str)
# data_dict = json.loads(data_str)
# print(type(data_dict))
# print(data_dict)
# bearer_access_token = data_dict["access_token"]

# response = json.loads(conn.getresponse().read().decode("utf-8"))

#
# initiate bulk user export job
#
# JSON
# Auth0's export files use the ndjson format due to the large size of the
# export files, while the import functionality expects a JSON file.
# payload = "{\"connection_id\": \"CONNECTION_ID\", \"format\": \"json\", \"limit\": 5, \"fields\": [{\"name\": \"email\"}, {\"name\": \"user_metadata.consent\"}]}"
# payload = f'{{"connection_id": "{CONNECTION_ID}", "format": "json", "limit": 5, "fields": [{{"name": "email"}}, {{"name": "user_metadata.consent"}}]}}'
# body = {
#     "connection_id": CONNECTION_ID,
#     "format": "json",
#     "limit": 5,
#     "fields": [
#         {"name": "email"},
#         {"name": "user_metadata.consent"}
#     ]
# }
# CSV
# payload = f"{{\"connection_id\": \"{CONNECTION_ID}\", \"format\": \"csv\", \"limit\": 5, \"fields\": [{{\"name\": \"email\"}}, {{ \"name\": \"identities[0].connection\", \"export_as\": \"provider\" }}]}}"

# body_dict = {
#     "connection_id": CONNECTION_ID,
#     "format": "json",
# }
body_dict = {
    "connection_id": connection_id,
    "format": "json",
    "limit": 5,
    "fields": [{"name": "email"}, {"name": "user_metadata.consent"}],
}
# body must be a string
body = json.dumps(body_dict)
headers = {
    "authorization": f"Bearer {bearer_access_token}",
    "content-type": "application/json",
}

# print(headers)

# conn.request("POST", f"/{DOMAIN}/api/v2/jobs/users-exports", payload, headers)
# conn.request("POST", f"/{USER_EXPORTS_PATH}", body, headers)

# res = conn.getresponse()
# print(res)
# data = res.read()
# data_dict = data.decode("utf-8")
# print(data_dict)
# JOB_ID = data.get("id")

# response = json.loads(conn.getresponse().read().decode("utf-8"))
# print(response)
# job_id = response.get("id")
# print(f"job_id: {job_id}")

# try urllib3
user_exports_url = f"https://{AUTH0_DOMAIN}/{USER_EXPORTS_PATH}"
headers = {
    "authorization": f"Bearer {bearer_access_token}",
    "content-type": "application/json",
}
body = json.dumps({
    "connection_id": connection_id,
    "format": "json",
}).encode("utf-8")
request = http.request("POST", user_exports_url, headers=headers, body=body)
response = json.loads(request.data.decode("utf-8"))
job_id = response.get("id")

#
# get job status
#
# headers = { 'authorization': "Bearer MGMT_API_ACCESS_TOKEN" }
job_status_url = f"https://{AUTH0_DOMAIN}/{JOB_STATUS_PATH}".format(**locals())
headers = {"authorization": f"Bearer {bearer_access_token}"}

# wait for a bit
print(f"sleeping for {SLEEP_TIME} second(s)")
time.sleep(SLEEP_TIME)

# conn.request("GET", "/DOMAIN/api/v2/jobs/JOB_ID", headers=headers)
# conn.request("GET", f"/{JOB_STATUS_PATH}".format(**locals()), headers=headers)
request = http.request("GET", job_status_url, headers=headers)
response = json.loads(request.data.decode("utf-8"))
# response = json.loads(conn.getresponse().read().decode("utf-8"))
# print(response)
status = response.get("status")
# print(f"status: {status}")
while status != "completed":
    # wait for a bit more
    print(f"sleeping for {SLEEP_TIME} seconds")
    time.sleep(SLEEP_TIME)
    request = http.request("GET", job_status_url, headers=headers)
    response = json.loads(request.data.decode("utf-8"))
    # response = json.loads(conn.getresponse().read().decode("utf-8"))
    # print(response)
    status = response.get("status")
    # conn.request("GET", f"/{JOB_STATUS_PATH}".format(**locals()), headers=headers)
    # status = json.loads(conn.getresponse().read().decode("utf-8")).get("status")
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
