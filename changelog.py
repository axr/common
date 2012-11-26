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

    ''' Returns the release date in a format appropriate for a Debian changelog '''
    def debianDate(self):
        if self.date == "Unreleased":
            return self.date
        else:
            return self.date.strftime('%a, %d %b %Y %H:%M:%S %z').strip()

    ''' Returns the release date in a format appropriate for an RPM changelog'''
    def rpmDate(self):
        if self.date == "Unreleased":
            return self.date
        else:
            return self.date.strftime('%a %b %d %Y')

    ''' Returns the release date (and time) in ISO 8601 format '''
    def isoDate(self):
        if self.date == "Unreleased":
            return self.date
        else:
            return self.date.isoformat()

    ''' Converts the Version structure to a dictionary '''
    def toDict(self):
        return dict(number=self.number, date=self.isoDate(), items=self.items)

''' A JSON encoder that writes Version structures '''
class VersionEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Version):
            return obj.toDict()
        return json.JSONEncoder.default(self, obj)

parser = argparse.ArgumentParser(description="Converts markdown changelogs to various alternate formats.")
parser.add_argument("--debian", type=argparse.FileType('w'), help="path to write Debian changelog to, or - for <stdout>")
parser.add_argument("--rpm", type=argparse.FileType('w'), help="path to write RPM changelog to, or - for <stdout>")
parser.add_argument("--json", type=argparse.FileType('w'), help="path to write JSON changelog to, or - for <stdout>")
parser.add_argument("package", help="name of the package being built")
parser.add_argument("changelog", type=argparse.FileType('r'), help="path to a changelog in markdown format or - for <stdin>")

args = parser.parse_args()

if args.changelog == sys.stdin:
    print("Enter the changelog contents in markdown format and press CTRL+D when done:", file=sys.stderr)

# List of versions with their number, release date, and change items
versions = []

# Read input from markdown file
lines = args.changelog.readlines()
for line in lines:
    # Strip the last \n on the line
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

if args.debian:
    for version in versions:
        print("%s (%s) unstable; urgency=low\n" % (args.package, version.number), file=args.debian)

        for item in version.items:
            print("  * %s\n" % item, file=args.debian)

        print(" -- AXR Project <team@axr.vg>  %s" % version.debianDate(), file=args.debian) # Yes, TWO spaces

        # Newline if this isn't the last version (else it ends with two)
        if version != versions[-1]:
            print(file=args.debian)

    if args.debian != sys.stdout:
        print("Wrote Debian changelog to " + args.debian.name, file=sys.stderr)

if args.rpm:
    for version in versions:
        print("* %s AXR Project <team@axr.vg> %s" % (version.rpmDate(), version.number), file=args.rpm)

        for item in version.items:
            print("- %s" % item, file=args.rpm)

        # Newline if this isn't the last version (else it ends with two)
        if version != versions[-1]:
            print(file=args.rpm)

    if args.rpm != sys.stdout:
        print("Wrote RPM changelog to " + args.rpm.name, file=sys.stderr)

if args.json:
    print(json.dumps(dict(package=args.package, changelog=versions), sort_keys=False, indent=4, cls=VersionEncoder), file=args.json)

    if args.json != sys.stdout:
        print("Wrote JSON changelog to " + args.json.name, file=sys.stderr)
