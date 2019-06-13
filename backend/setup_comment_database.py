import sys
import requests
import json


if __name__ == "__main__":
    assert(len(sys.argv) == 2)
    app_ID = sys.argv[1]

    with open("./docs/output.json") as f:
        course_json = json.load(f)

    for course in course_json:
        number = course["number"]
        print("Uploading " + number)
        headers = {"X-Parse-Application-Id": app_ID,\
                   "content-Type": "application/json"}
        data = json.dumps({"courseNumber": number, "comments": []})
        url = 'https://fceplusplus.herokuapp.com/parse/classes/Comments'
        requests.post(url, data=data, headers=headers)
