VENV=venv/bin/activate
OUTPUT_DIR=output
HASHTAG_SCRIPT=crawl-hdx.py
HASHTAG_DATA=$(OUTPUT_DIR)/hdx-hashtag-stats.csv
CKAN_TAG_SCRIPT=ckan-tags.py
CKAN_TAG_DATA=$(OUTPUT_DIR)/hxl-ckan-tags.csv

DATA_SERIES_DATA=$(OUTPUT_DIR)/data-series.csv

REPORTS=$(OUTPUT_DIR)/report-hashtags-by-data-series.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-data-series.csv \
	$(OUTPUT_DIR)/report-hashtags-by-org.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-org.csv

all: hashtag-data ckan-tags

hashtag-data: $(HASHTAG_DATA)

ckan-tags: $(CKAN_TAG_DATA)

data-series: $(DATA_SERIES_DATA)

reports: $(REPORTS)

$(HASHTAG_DATA): $(VENV) $(HASHTAG_SCRIPT)
	. $(VENV) && python3 $(HASHTAG_SCRIPT) > $@

$(CKAN_TAG_DATA): $(VENV) $(CKAN_TAG_SCRIPT) $(DATA_SERIES_DATA)
	. $(VENV) && python3 $(CKAN_TAG_SCRIPT) | hxlmerge -k meta+dataset -t meta+hash -m $(DATA_SERIES_DATA) > $@

$(DATA_SERIES_DATA): $(VENV) $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) | hxlcut -i meta+dataset,meta+hash | hxlsort -t meta+hash | hxldedup -t meta+dataset > $@

# Reports

$(OUTPUT_DIR)/report-hashtags-by-data-series.csv: $(HASHTAG_DATA) $(DATA_SERIES_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxlcut -i meta+tag,meta+dataset \
	| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
	| hxldedup -t meta+tag,meta+hash \
	| hxlcount -t meta+tag \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-tagspecs-by-data-series.csv: $(HASHTAG_DATA) $(DATA_SERIES_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxlcut -i meta+tagspec,meta+dataset \
	| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
	| hxldedup -t meta+tagspec,meta+hash \
	| hxlcount -t meta+tagspec \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-hashtags-by-org.csv: $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxlcut -i meta+tag,org \
	| hxldedup -t meta+tag,org \
	| hxlcount -t meta+tag \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-tagspecs-by-org.csv: $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxlcut -i meta+tagspec,org \
	| hxldedup -t meta+tagspec,org \
	| hxlcount -t meta+tagspec \
	| hxlsort -r -t meta+count \
	> $@


# Admin

$(VENV):
	rm -rf venv && python3 -m venv venv && pip3 install -r requirements.txt

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

sync:
	git checkout main && git pull origin main && git push origin main

clean-all: clean-reports clean-venv

clean-reports:
	rm -f $(REPORTS)

clean-venv:
	rm -rf venv

