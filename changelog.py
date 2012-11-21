#!/usr/bin/env python

from __future__ import print_function
import datetime
import json
import os
import re
import sys

if sys.version_info < (2,6):
    print("must be run with at least Python 2.6", file=sys.stderr)
    sys.exit(1)

try:
    import argparse
except ImportError:
    print("Could not find argparse module! This indicates you are running a version of Python "
        "older than 2.7. Run `sudo easy_install argparse` to install it and try again.")
    sys.exit(1)

''' Class that stores a version's number, release date, and list of change items '''
class Version:
    def __init__(self, number, date):
        self.number = number
        if date == "Unreleased":
            self.date = date
        else:
            self.date = datetime.datetime.strptime(date, "%Y-%m-%d").date()
        self.items = []

    def debianDate(self):
        if self.date == "Unreleased":
            return self.date
        else:
            return self.date.strftime('%a, %b %d %Y %H:%M:%S %z').strip()

    def rpmDate(self):
        if self.date == "Unreleased":
            return self.date
        else:
            return self.date.strftime('%a %b %d %Y')

    def isoDate(self):
        if self.date == "Unreleased":
            return self.date
        else:
            return self.date.isoformat()

    def toDict(self):
        return dict(number=self.number, date=self.isoDate(), items=self.items)

class VersionEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Version):
            return obj.toDict()
        return json.JSONEncoder.default(self, obj)

parser = argparse.ArgumentParser(description="Converts our changelog format to various alternate formats.")
parser.add_argument("--debian", action="store", help="Filename to write Debian changelog to")
parser.add_argument("--rpm", action="store", help="Filename to write RPM changelog to")
parser.add_argument("--json", action="store", help="Filename to write JSON changelog to")
parser.add_argument("package", help="Name of the package being built")
parser.add_argument("changelog", help="Filename of our changelog in markdown format")

args = parser.parse_args()

inputPath = os.path.realpath(args.changelog)

# List of versions with their number, release date, and change items
versions = []

if os.path.isfile(inputPath):
    with open(inputPath, "r+") as f:
        lines = f.readlines()

        for line in lines:
            # Strip the last \n
            line = line[:-1]

            match = re.match("^### Version (?P<version_number>[0-9]+\.[0-9]+(\.[0-9]+(\.[0-9]+)?)?) - (?P<release_date>([0-9]{4}-[0-9]{2}-[0-9]{2})|Unreleased)$", line)
            if match:
                # New version section
                versions.append(Version(match.group("version_number"), match.group("release_date")))
            elif line.startswith("* "):
                # Add new change item
                versions[-1].items.append(line[2:])
            elif line.startswith("  "):
                # Continuation of last change item, append it
                versions[-1].items[-1] += (line[1:])
else:
    print(args.changelog + " not found")
    sys.exit(1)

if args.debian:
    debianPath = os.path.realpath(args.debian)

    with open(debianPath, "w+") as f:
        for version in versions:
            print("%s (%s) unstable; urgency=low\n" % (args.package, version.number), file=f)

            for item in version.items:
                print("  * %s\n" % item, file=f)

            print(" -- AXR Project <team@axr.vg>  %s" % version.debianDate(), file=f) # Yes, TWO spaces

            # Newline if this isn't the last version (else it ends with two)
            if version != versions[-1]:
                print(file=f)

    print("Wrote Debian changelog to " + debianPath)

if args.rpm:
    rpmPath = os.path.realpath(args.rpm)

    with open(rpmPath, "w+") as f:
        for version in versions:
            print("* %s AXR Project <team@axr.vg> %s" % (version.rpmDate(), version.number), file=f)

            for item in version.items:
                print("- %s" % item, file=f)

            # Newline if this isn't the last version (else it ends with two)
            if version != versions[-1]:
                print(file=f)

    print("Wrote RPM changelog to " + rpmPath)

if args.json:
    jsonPath = os.path.realpath(args.json)

    with open(jsonPath, "w+") as f:
        print(json.dumps(dict(package=args.package, changelog=versions), sort_keys=False, indent=4, cls=VersionEncoder), file=f)

    print("Wrote JSON changelog to " + jsonPath)
