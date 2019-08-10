#!/usr/bin/env python3

import argparse
import csv
import os
import json
import cmu_course_api

import pandas as pd

"""
Adapted from Marat Valiev's CMUnits FCE parser: 
https://github.com/cmu-student-government/cmunit

Uses Scottylab's cmu_course_api to scrape course descriptions and prereqs

The goal is to get a json like:
[
    {
        "number": "15-122"
        "hours per week": 13.8,
        "overall course rate": 3.9,
        "desc": "For students with a basic understanding of programming...",
        "prereqs": "15-112",
        "prereqs_obj": {
            "invert": false,
            "reqs_list": [
                [
                    "15-112"
                ]
            ]
        },
        "coreqs": "21-127 or 15-151",
        "coreqs_obj": {
            "invert": false,
            "reqs_list": [
                [
                    "21-127",
                    "15-151"
                ]
            ]
        },
        "name": "Principles of Imperative Computation",
        "units": 10.0,
        "department": "SCS: Computer Science",
        "instructors": [
            {
                "Instructor name": "CERVESATO, ILIANO"
                "Hours per week": 13.0,
                "Interest in student learning": 3.8,
                "Clearly explain course requirements": 3.8,
                "Clear learning objectives & goals": 3.9,
                "Instructor provides feedback to students to improve": 3.4,
                "Demonstrate importance of subject matter": 4.1,
                "Explains subject matter of course": 3.7,
                "Show respect for all students": 4.0,
                "Overall teaching rate": 3.5,
                "Overall course rate": 3.8
                }
            },
            {
                "Instructor name": "KAYNAR, DILSUN"
                "Hours per week": 13.2,
                ...
            },
            ...
        ]
    },
    {
        "number": "xx-xxx",
        ...
    },
    ...
]    
"""

def format_hyphen(s):
    #formats the course name as "xx-xxx"
    if s.find("-") != -1: # some of the data is alredy partly fomatted
        return s[-5:]
    else: # most is in the form "xxxxx.0"
        s = str(int(s))
        return s[0:2] + "-" + s[2:6]

def refresh_data():
    #reloads the course descriptions and prereqs
    fall = cmu_course_api.get_course_data('F')
    spring = cmu_course_api.get_course_data('S')
    spring.update(fall)
    all_data = spring
    with open("./docs/course_descriptions.json", "w") as f:
        json.dump(all_data["courses"], f)

if __name__ == '__main__':
    print("Compiling data...")
    parser = argparse.ArgumentParser(
        description="Compile CSV exported from FCE into a machine-readable "
                    "format")
    parser.add_argument('--callback', default="", nargs="?",
                        help='JSONP callback to enable cross-domain requests. '
                             'Default: none')
    parser.add_argument('-i', '--input', default="docs/FCEtable.csv", nargs="?",
                        type=argparse.FileType('r'),
                        help='Input CSV file, exported from cmu.smartevals.com.'
                             ' Default: ./docs/FCEtable.csv.')
    parser.add_argument('-o', '--output', default="docs/output.json", nargs="?",
                        type=argparse.FileType('w'),
                        help='Filename to export JSON data. '
                             'Default: ./docs/output.json')
    args = parser.parse_args()

    df = pd.read_csv(args.input).rename(
            columns={'Year': 'year', 'Name': 'instructor', 'Course Name': 'name'})

    # remove the qatar classes
    df = df[(df['Section'] != "Q") & (df['Section'] != "W")]

    # get one hours column and remove any data that has no reported hours or <5 respondents
    df['Hours per week'] = df[['Hrs Per Week', 'Hrs Per Week 5', 'Hrs Per Week 8']].max(axis=1)
    df = df[pd.notnull(df['Hours per week']) & (df['Num Respondents'] >= 5)]

    # get course name like 'xx-xxx' 
    df['course id'] = df['Course ID'].map(
        lambda s: format_hyphen(s))

    # Summer courses are usually more intensive and thus not representative
    df = df[df["Semester"] != "Summer"]
    # information older than two years is probably not relevant
    df = df[df['year'] > 2016]
   
    # uncomment this to re-scrape all of the course information
    # warning - takes 5-10 minutes to scrape all of the data
    # refresh_data()

    # loads the course data from the json
    with open("./docs/course_descriptions.json") as f:
        course_data = json.load(f)

    # the headings that will be used from the course data json
    headings = ['name', 'department', 'units', 'desc', 'prereqs', 
                'prereqs_obj', 'coreqs', 'coreqs_obj']

    courses = [] 
    # loop through each course
    for course_name, course_info in df.groupby("course id"):
        # average its hours and rating
        avg = course_info[['Hours per week', 'Overall course rate']].mean(axis=0)
        # generate a new dictionary for that course and put the average hours and rate in
        course = dict()
        course["number"] = course_name
        course["hours per week"] = round(avg['Hours per week'],1)
        course["overall course rate"] = round(avg['Overall course rate'],1)
        if course_name in course_data:
            data = course_data[course_name]
            for key in data:
                # fill up the dictionary with the info from the course descriptions json
                if key != "lectures" and key != "sections":
                    course[key] = data[key]
        else:
            continue
        instructor_list = [] # list of each instructor and their ratings from the FCE
        for name, instructor_info in course_info.groupby("instructor"):
            avg_info = instructor_info[["Hours per week", 'Interest in student learning', 
                'Clearly explain course requirements', 'Clear learning objectives & goals', 
                'Instructor provides feedback to students to improve', 
                'Demonstrate importance of subject matter', 'Explains subject matter of course',
                'Show respect for all students', 'Overall teaching rate', 
                'Overall course rate']].mean(axis=0).round(1)
            # append each instructor's json to the list
            instructor_dict = json.loads(avg_info.to_json(orient='index'))

            first_name = name[name.find(",")+2:]
            second_name = name[:name.find(",")]
            reordered_name = first_name.lower() + " " + second_name.lower()

            words = reordered_name.split(" ")
            for i in range(len(words)):
                words[i] = words[i][0].upper() + words[i][1:]

            new_name = " ".join(words)

            instructor_dict['Instructor name'] = new_name
            instructor_list.append(instructor_dict)
        course["instructors"] = instructor_list
        courses.append(course)

    # write it all to the output file
    with open("docs/output.json", "w") as write_file:
        print("Writing to file...")
        json.dump(courses, write_file, indent=4)

    print("Done")
