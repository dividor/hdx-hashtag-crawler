Free script to crawl HDX and collect stats about HXL hashtag usage

## Requirements

- Python3
- ckanapi package
- libhxl package
- requests package

## Setup

    pip install -r requirements.txt

## Usage

    python3 crawl-hdx.py > results.csv

## Analysing the results

All examples send HXL-hashtagged CSV to standard output. Unix-like shell assumed. libhxl package must be installed (see Setup).

Count occurrences for each HXL hashtag, sorted in descending frequency:

    cat results.csv | hxlcount -t meta+tag | hxlsort -t meta+count -r

Same for each HXL hashtag+attributes sequence:

    cat results.csv | hxlcount -t meta+tagspec | hxlsort -t meta+count -r

Count each header/hashtag+attributes combination:

    cat results.csv | hxlcount -t meta+header,meta+tagspec

Count number of unique organisations using each header/hashtag+attributes combination:

    cat results.csv | hxlcount -t meta+header,meta+tagspec,org | hxlcount -t meta+header,meta+tagspec

## Links

About HXL: http://hxlstandard.org
HDX: https://data.humdata.org

