""" Create a row for each attribute in the hashtag report.
"""

import csv, hxl, sys

output = csv.writer(sys.stdout)

output.writerow([
    "Attribute",
    "Hashtag",
    "Hashtag with Attributes",
    "Text header",
    "Locations",
    "Data provider",
    "HDX dataset id",
    "HDX resource id",
    "Date created",
    "Hash",
])

output.writerow([
    "#meta+attribute",
    "#meta+tag",
    "#meta+tagspec",
    "#meta+header",
    "#country+code",
    "#org+provider",
    "#meta+dataset",
    "#meta+resource",
    "#date+created",
    "#meta+hash",
])

with hxl.data(sys.stdin.buffer) as input:
    for row in input:
        tagspec = row.get("meta+tagspec")
        column = hxl.model.Column.parse(tagspec)

        countries = sorted(row.get("country+code+list").split(","))
        if not countries:
            countries = [""] # make sure we get each attribute at least once
        countries = [country.upper() for country in countries]

        attributes = sorted(column.attributes)
        if not attributes:
            attributes = [""] # make sure we get at least one row for each

        for attribute in attributes:
            for country in countries:
                output.writerow([
                    "+" + attribute,
                    column.tag,
                    tagspec,
                    row.get("#meta+header"),
                    country,
                    row.get("#org+provider"),
                    row.get("#meta+dataset"),
                    row.get("#meta+resource"),
                    row.get("#date+created"),
                    row.get("#meta+hash"),
                ])
