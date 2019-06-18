import sys
import requests
import json

'''
This file manages the comment objects stored on the Parse server
The comments are stored in a JSON array formatted like so:

[
    {
        "objectId": "xxxxxxx",
        "courseNumber": "xx-xxx"
        "createdAt": "2019-06-...."
        "updatedAt": "2016-06-..."
        "comments": [
            {
                "andrewID": "sflatter",
                "commentText": "..."
                "timePosted": "MON DD, YYYY at H:MM AM/PM"
                "anonymous": true/false
            }
        ]
    },
    ...

]

It has three main functions:
    1. Download the comment objects onto my local machine
    2. Update the comment objects with new courses each semester
    3. Restore the comments on the server with the locally
       stored data
'''

def store_comments_locally(app_ID):
    # downloads the comments from the database locally
    print("Downloading...")
    headers = {"X-Parse-Application-Id": app_ID,\
               "X-Parse-Rest-API-Key": ""}
    url = 'https://fceplusplus.herokuapp.com/parse/classes/Comments'
    params = {"limit":1500} 
    # get at most 1500 responses, there are 1.07k comment objects
    # so this is more than adequate
    response = requests.get(url, params=params, headers=headers)
    response_json = response.json()
    # returns a json like:
    # { results : [array of comment data] }
    comments = response_json["results"]
    print(comments)
    with open("./docs/comments.json", "w") as f:
        print("Writing to file...")
        json.dump(comments, f, indent=4)

def update_comments(app_ID):
    # add new comment objects for future courses when 
    # the FCEs are updated
    store_comments_locally(app_ID) # make sure local is up to date

    with open("./docs/comments.json") as f:
        comments_json = json.load(f)

    with open("./docs/output.json") as f:
        course_json = json.load(f)
    
    updated_courses = False # have any new courses been added?

    headers = {"X-Parse-Application-Id": app_ID, \
               "X-Parse-Rest-API-Key": "", \
               "Content-Type": "application/json"}
    url = 'https://fceplusplus.herokuapp.com/parse/classes/Comments'

    for course in course_json:
        for course_comments in comments_json:
            if course["number"] == course_comments["courseNumber"]:
                # if there exists a comment object for the given course, break
                # out of the iteration through the comments and bypass the else statement
                break
        else:
            # runs if inner loop not broken
            # send a post request to the server with the new course number
            number = course["number"]
            print("Updating " + number)
            data = json.dumps({"courseNumber": number, "comments": []})
            print(data)
            updated_courses = True
            response = requests.post(url, data=data, headers=headers)
            print(response)

    if not updated_courses:
        print("All courses were up to date")
    else:
        # store the changes locally 
        print("Storing updates locally...")
        store_comments_locally(app_ID)

def restore_comments_from_local(app_ID):
    # restore the comment objects' arrays from the locally saved data
    with open("./docs/comments.json") as f:
        comment_objects = json.load(f)

    url = 'https://fceplusplus.herokuapp.com/parse/classes/Comments'
    headers = {"X-Parse-Application-Id": app_ID, \
               "X-Parse-Rest-API-Key": "", \
               "Content-Type": "application/json"}

    for comment_obj in comment_objects:
        # loop through the locally stored comment objects
        local_comments = comment_obj["comments"] # get the actual comment array
        print("updating " + comment_obj["courseNumber"])
        #make a new json with the comment array
        comment_json = json.dumps({"comments": local_comments})
        # put the changes into the comment object's ID
        requests.put(url + "/" + comment_obj["objectId"], data=comment_json, headers=headers)

if __name__ == "__main__":
    assert(len(sys.argv) == 2)
    app_ID = sys.argv[1]
    print("What do you want to do?")
    print("Update the existing data with new courses [u]")
    print("Download the comment data locally [d]")
    print("Restore the comments from the local backup [r]")
    action = str(input("Please make a selection [u/d/r]: "))
    while action != "u" and action != "d" and action!= "r":
        action = str(input("Please enter either 'u', or 'd' or 'r': "))
    if action == "u":
        updated = update_comments(app_ID)
    elif action == "d":
        store_comments_locally(app_ID)
        print("The comment data was downloaded into docs/comments.json")
    elif action == "r":
        restore_comments_from_local(app_ID)
    else:
        print("Something went wrong, please try running the program again")
