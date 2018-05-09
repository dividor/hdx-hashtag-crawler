"""Crawl HXL to build a glossary of tagspecs and headers
CKAN API documentation: http://docs.ckan.org/en/latest/api/
Python CKAN library: https://github.com/ckan/ckanapi

Started by David Megginson, 2018-05-09
"""

import ckanapi, hxl, logging, time, sys, csv

# Set up a logger
logging.basicConfig(stream=sys.stderr, level=logging.INFO)

DELAY = 2
"""Time delay in seconds between datasets, to give HDX a break."""

CHUNK_SIZE=100
"""Number of datasets to read at once"""

CKAN_URL = 'https://data.humdata.org'
"""Base URL for the CKAN instance."""

# Open a connection to HDX
ckan = ckanapi.RemoteCKAN(CKAN_URL)

# Open a CSV output stream
output = csv.writer(sys.stdout)

# Iterate through all the datasets ("packages") and resources on HDX
start = 0
result_count = 999999 # just a big, big number; will reset on first search result

output.writerow([
    'Hashtag spec',
    'Text header',
    'Locations',
    'Data provider',
    'HDX dataset id',
    'Date created',
])
    
output.writerow([
    '#meta+tag',
    '#meta+header',
    '#country+code+list',
    '#org+provider',
    '#meta+dataset',
    '#date+created',
])
    
while start < result_count:
    result = ckan.action.package_search(fq='tags:hxl', start=start, rows=CHUNK_SIZE)
    result_count = result['count']
    logging.info("Read %d package(s)...", len(result['results']))
    for package in result['results']:
        package_id = package['name']
        org_id = package['organization']['id']
        location_ids = ' '.join([group['id'] for group in package['groups']])
        date_created = package['metadata_created'][:10]
        for resource in package['resources']:
            try:
                with hxl.data(resource['url']) as source:
                    for i, column in enumerate(source.columns):
                        if column.tag:
                            output.writerow([
                                column.get_display_tag(sort_attributes=True),
                                column.header,
                                location_ids,
                                org_id,
                                package_id,
                                date_created,
                            ])
            except Exception as e:
                logging.warning("Failed to parse as HXL (%s): %s", str(e), resource['url'])
    start += CHUNK_SIZE # next chunk, but first ...
    time.sleep(DELAY) # give HDX a short rest

# end
