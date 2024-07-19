"""Crawl HXL to build a glossary of tagspecs and headers
CKAN API documentation: http://docs.ckan.org/en/latest/api/
Python CKAN library: https://github.com/ckan/ckanapi

Started by David Megginson, 2018-05-09
"""

import ckanapi, hxl, logging, time, sys, csv, json, os

# Set up a logger
logging.basicConfig(stream=sys.stderr, level=logging.WARNING)
logger = logging.getLogger(__name__)

DELAY = 2
"""Time delay in seconds between datasets, to give HDX a break."""

CHUNK_SIZE=100
"""Number of datasets to read at once"""

CKAN_URL = 'https://data.humdata.org'
"""Base URL for the CKAN instance."""

USER_AGENT='HDXINTERNAL HXL hashtag analysis'
"""User agent (for analytics)"""

DATA_DIR = './data'

# Open a connection to HDX
ckan = ckanapi.RemoteCKAN(CKAN_URL, user_agent=USER_AGENT)

results_file = f'{DATA_DIR}/results.csv'

# If results file exists get list of resource_ids
# If not, create a new file
processed_resources = []
if os.path.exists(results_file):
    with open(results_file, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            processed_resources.append(row[6])
    output = csv.writer(open(results_file, 'a'))
else:
    output = csv.writer(open(results_file, 'w'))

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
    'Hash',
    'Quick Charts',
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
    '#meta+hash',
    '#meta+has_quickcharts',
])

if not os.path.exists('./data'):
    os.makedirs('./data')

def save_data(resource, source):

    file_name_stub = f"{resource['name'].replace(' ', '_')}_{resource['id']}"
    metadata_file_name = f'./data/{file_name_stub}_metadata.json'
    data_file_name = f'./data/{file_name_stub}.{resource["format"]}'

    with open(metadata_file_name, 'w') as f:
        f.write(json.dumps(resource, indent=2))
          
    with open(data_file_name, 'w') as f:
        writer = csv.writer(f)
        writer.writerow([column.display_tag for column in source.columns])
        for row in source:
            writer.writerow(row.values)


while start < result_count:
    result = ckan.action.package_search(fq='vocab_Topics:hxl', start=start, rows=CHUNK_SIZE)
    result_count = result['count']
    print(f"{start/result_count*100:.2f}%")
    for package in result['results']:
        package_id = package['name']
        org_id = package['organization']['name']
        location_ids = ' '.join([group['id'] for group in package['groups']])
        date_created = package['metadata_created'][:10]
        input_options = hxl.input.InputOptions(http_headers={'User-Agent': USER_AGENT})
        for resource in package['resources']:

            resource_id = resource.get('id')

            # Skip resources that have already been processed and saved, so script can be restarted
            if resource_id in processed_resources:
                print(f"    Skipping {resource_id}, already processed")
                continue
            else:
                print(f"    Processing {resource_id}")

            try:
                with hxl.data(resource['url'], input_options) as source:

                    # Save the data for file
                    save_data(resource, source)
                    
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
                                resource_id,
                                date_created,
                                hex(abs(column_hash)),
                                'true' if package['has_quickcharts'] else 'false',
                            ])
                    processed_resources.append(resource_id)
            except Exception as e:
                logger.warning("Failed to parse resource %s in dataset %s as HXL (%s): %s", resource['id'], package['name'], str(e), resource['url'])
            time.sleep(DELAY) # give HDX a short rest
    start += CHUNK_SIZE # next chunk

# end
