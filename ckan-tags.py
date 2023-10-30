""" Find tags correlated with HXL datasets
"""

import ckancrawler, csv, sys

URL = 'https://data.humdata.org'
""" HDX URL
"""

SEARCH_FQ = 'vocab_Topics:hxl'
""" CKAN tag for HXL
"""

USER_AGENT = 'HDXINTERNAL CKAN tag analysis for HXL'
""" User agent to pass to CKAN (for analytics)
"""

crawler = ckancrawler.Crawler(URL, delay=0, user_agent=USER_AGENT)

output = csv.writer(sys.stdout)

output.writerow([
    "Dataset",
    "Organisation",
    "CKAN tag",
])

output.writerow([
    "#meta+dataset",
    "#org+provider",
    "#meta+tag",
])

for dataset in crawler.packages(fq=SEARCH_FQ):

    for tag in dataset['tags']:
        if tag['name'] != 'hxl':
            output.writerow([
                dataset['name'],
                dataset['organization']['name'],
                tag['name'],
            ])

sys.exit(0)

