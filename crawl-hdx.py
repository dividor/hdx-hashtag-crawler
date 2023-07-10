"""Crawl HXL to build a glossary of tagspecs and headers
CKAN API documentation: http://docs.ckan.org/en/latest/api/
Python CKAN library: https://github.com/ckan/ckanapi

Started by David Megginson, 2018-05-09
"""

import ckanapi, hxl, logging, time, sys, csv

# Set up a logger
logging.basicConfig(stream=sys.stderr, level=logging.ERROR)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DELAY = 2
"""Time delay in seconds between datasets, to give HDX a break."""

CHUNK_SIZE=100
"""Number of datasets to read at once"""

CKAN_URL = 'https://data.humdata.org'
"""Base URL for the CKAN instance."""

USER_AGENT='HDX-Developer-2015'
"""User agent (for analytics)"""


# Open a connection to HDX
ckan = ckanapi.RemoteCKAN(CKAN_URL, user_agent=USER_AGENT)

# Open a CSV output stream
output = csv.writer(sys.stdout)

# Iterate through all the datasets ("packages") and resources on HDX
start = 0
result_count = 999999 # just a big, big number; will reset on first search result

output.writerow([
    'Hashtag',
    'Hashtag with attributes',
    'Text header',
    'Locations',
    'Data provider',
    'HDX dataset id',
    'HDX resource id',
    'Date created',
    'Hash'
])
    
output.writerow([
    '#meta+tag',
    '#meta+tagspec',
    '#meta+header',
    '#country+code+list',
    '#org+provider',
    '#meta+dataset',
    '#meta+resource',
    '#date+created',
    '#meta+hash'
])
    
while start < result_count:
    result = ckan.action.package_search(fq='vocab_Topics:hxl', start=start, rows=CHUNK_SIZE)
    result_count = result['count']
    logger.info("Read %d package(s)...", len(result['results']))
    for package in result['results']:
        package_id = package['name']
        org_id = package['organization']['name']
        location_ids = ' '.join([group['id'] for group in package['groups']])
        date_created = package['metadata_created'][:10]
        input_options = hxl.input.InputOptions(http_headers={'User-Agent': USER_AGENT})
        for resource in package['resources']:
            try:
                with hxl.data(resource['url'], input_options) as source:
                    # assumption is that two datasets with exactly the same hashtags+attributes
                    # in exactly the same order are probably programmatic/API-based variants of
                    # the same source data
                    column_hash = hash(tuple([column.display_tag for column in source.columns]))
                    for i, column in enumerate(source.columns):
                        if column.tag:
                            output.writerow([
                                column.tag,
                                column.get_display_tag(sort_attributes=True),
                                column.header,
                                location_ids,
                                org_id,
                                package_id,
                                resource.get('id'),
                                date_created,
                                hex(abs(column_hash)),
                            ])
            except Exception as e:
                logger.warning("Failed to parse as HXL (%s): %s", str(e), resource['url'])
            time.sleep(DELAY) # give HDX a short rest
    start += CHUNK_SIZE # next chunk

# end
