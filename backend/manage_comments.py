#!/usr/bin/env python3

import myjson
import json

"""
The comments are stored in a JSON array like so:

[
    {
        "courseName": "15-122",
        "comments": [....] (an array of string comments)
    },
    {
        "courseName": "15-131",
        "comments": [....]
    },
    ...
]

This file creates, updates and downloads the JSON data from the online
JSON hosting service myjson.com
"""

url = "https://api.myjson.com/bins/depeh"

def setup_web_hosting():
    courses = []

    with open("./docs/output.json") as f:
        course_json = json.load(f)

    for course in course_json:
        number  = course["number"]
        course_comments = {"courseNumber": number, "comments": []}
        courses.append(course_comments)

    json_string = json.dumps(courses)
    url = myjson.store(json_string)
    return url

def update_web_data():

    with open("./docs/comments.json") as f:
        comments = json.load(f)

    with open("./docs/output.json") as f:
        course_json = json.load(f)

    updated_courses = []
    for course in course_json:
        for course_comments in comments:
            if course["number"] == course_comments["courseNumber"]:
                break
        else:
            number = course["number"]
            course_comments = {"courseNumber": number, "comments": []}
            course_json.append(course_comments)
            json_string = json.dumps(course_json)
            myjson.store(json_string, update=url)
            updated_courses.append(number)
            print("Added {}".format(number))

    if updated_courses == []:
        print("All courses were up to date")
    else:
        print("Storing updates locally...")
        store_comments_locally()

def restore_comments():
    print("Restoring...")
    with open("./docs/comments.json") as f:
        comments = json.load(f)

    json_string = json.dumps(comments)
    myjson.store(json_string, update=url)
    print("Done")

def store_comments_locally():
    comments = json.loads(myjson.get(url))

    with open("./docs/comments.json", "w") as write_file:
        json.dump(comments, write_file, indent=4)
    
if __name__ == "__main__":
    print("What do you want to do?")
    print("Setup a new url to host the data [s]")
    print("Update the existing data [u]")
    print("Download the comment data locally [d]")
    print("Restore the comments from a local file [r]")
    action = str(input("Please make a selection [s/u/d/r]: "))
    while action != "s" and action != "u" and action != "d" and action!= "r":
        action = str(input("Please enter either 's', 'u', or 'd': "))
    if action == "s":
        new_url = setup_web_hosting()
        print("The URL of the data is {}".format(new_url))
        # write the new url to the file
    elif action == "u":
        updated = update_web_data()
    elif action == "d":
        store_comments_locally()
        print("The comment data was downloaded into docs/comments.json")
    elif action == "r":
        restore_comments()
    else:
        print("Something went wrong, please try running the program again")

        
    

