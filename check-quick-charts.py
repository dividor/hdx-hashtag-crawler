""" Check which datasets have Quick Charts
"""

import ckanapi, csv, hxl, sys, time

CKAN_URL = 'https://data.humdata.org'
"""Base URL for the CKAN instance."""

DELAY = 0
"""Time delay in seconds between datasets, to give HDX a break."""

USER_AGENT='HDXINTERNAL HXL hashtag analysis'
"""User agent (for analytics)"""

ckan = ckanapi.RemoteCKAN(CKAN_URL, user_agent=USER_AGENT)
output = csv.writer(sys.stdout)

output.writerow(["#meta+dataset", "#date_created", "#org+provider", "#meta+quickcharts"])

if __name__ == "__main__":
    with hxl.data(sys.argv[1], hxl.InputOptions(allow_local=True)) as data:
        for row in data:
            row.get("#meta+dataset")
            package = ckan.action.package_show(id=row.get("#meta+dataset"))
            output.writerow(row.values + [package["has_quickcharts"]])
            time.sleep(DELAY)
