""" Find datasets with Quick Charts
"""

import ckancrawler, csv, sys

URL = 'https://data.humdata.org'
""" HDX URL
"""

SEARCH_FQ = 'vocab_Topics:hxl'
""" CKAN tag for HXL
"""

USER_AGENT = 'HDXINTERNAL Quick Charts analysis for HXL'
""" User agent to pass to CKAN (for analytics)
"""

crawler = ckancrawler.Crawler(URL, delay=0, user_agent=USER_AGENT)

output = csv.writer(sys.stdout)

output.writerow([
    "Dataset",
    "Organisation",
])

output.writerow([
    "#meta+dataset",
    "#org+provider",
    "#meta+has_quickcharts",
])

i = 0
for dataset in crawler.packages(fq=SEARCH_FQ):

    i += 1

    if (i % 100) == 0:
        print("{}...".format(i), file=sys.stderr)

    if dataset['has_quickcharts']:
        output.writerow([
            dataset['name'],
            dataset['organization']['name'],
            'true',
        ])

sys.exit(0)

