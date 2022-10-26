VENV=venv/bin/activate
OUTPUT_DIR=output
HASHTAG_SCRIPT=crawl-hdx.py
HASHTAG_DATA=$(OUTPUT_DIR)/hdx-hashtag-stats.csv
EXPANDED_SCRIPT=expand-data.py
EXPANDED_DATA=$(OUTPUT_DIR)/hdx-expanded-stats.csv
CKAN_TAG_SCRIPT=ckan-tags.py
CKAN_TAG_DATA=$(OUTPUT_DIR)/hxl-ckan-tags.csv

DATA_SERIES_DATA=$(OUTPUT_DIR)/data-series.csv

REPORTS=$(OUTPUT_DIR)/report-hashtags-by-data-series.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-data-series.csv \
	$(OUTPUT_DIR)/report-attributes-by-data-series.csv \
	$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-data-series.csv \
	$(OUTPUT_DIR)/report-hashtags-by-resource-type.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-resource-type.csv \
	$(OUTPUT_DIR)/report-attributes-by-resource-type.csv \
	$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-resource-type.csv \
	$(OUTPUT_DIR)/report-hashtags-by-org.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-org.csv \
	$(OUTPUT_DIR)/report-attributes-by-org.csv \
	$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-org.csv

all: hashtag-data ckan-tags

hashtag-data: $(HASHTAG_DATA)

expanded-data: $(EXPANDED_DATA)

ckan-tags: $(CKAN_TAG_DATA)

data-series: $(DATA_SERIES_DATA)

reports: $(REPORTS)

$(HASHTAG_DATA): $(VENV) $(HASHTAG_SCRIPT)
	. $(VENV) && python3 $(HASHTAG_SCRIPT) > $@

$(EXPANDED_DATA): $(VENV) $(EXPANDED_SCRIPT) $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) | python3 $(EXPANDED_SCRIPT) > $@

$(CKAN_TAG_DATA): $(VENV) $(CKAN_TAG_SCRIPT) $(DATA_SERIES_DATA)
	. $(VENV) && python3 $(CKAN_TAG_SCRIPT) | hxlmerge -k meta+dataset -t meta+hash -m $(DATA_SERIES_DATA) > $@

$(DATA_SERIES_DATA): $(VENV) $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) | hxlcut -i meta+dataset,meta+hash | hxlsort -t meta+hash | hxldedup -t meta+dataset > $@

# Reports

$(OUTPUT_DIR)/report-hashtags-by-data-series.csv: $(HASHTAG_DATA) $(DATA_SERIES_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxlcut -x meta+hash \
	| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
	| hxldedup -t meta+tag,meta+hash \
	| hxlcount -t meta+tag \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-tagspecs-by-data-series.csv: $(HASHTAG_DATA) $(DATA_SERIES_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxlcut -x meta+hash \
	| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
	| hxldedup -t meta+tagspec,meta+hash \
	| hxlcount -t meta+tagspec \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-attributes-by-data-series.csv: $(EXPANDED_DATA) $(DATA_SERIES_DATA)
	. $(VENV) && cat $(EXPANDED_DATA) \
	| hxlcut -x meta+hash \
	| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
	| hxldedup -t meta+attribute,meta+hash \
	| hxlcount -t meta+attribute \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-data-series.csv: $(EXPANDED_DATA) $(DATA_SERIES_DATA)
	. $(VENV) && cat $(EXPANDED_DATA) \
	| hxlcut -x meta+hash \
	| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
	| hxldedup -t meta+tag,meta+attribute,meta+hash \
	| hxlcount -t meta+tag,meta+attribute \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-hashtags-by-resource-type.csv: $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxldedup -t meta+tag,meta+hash \
	| hxlcount -t meta+tag \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-tagspecs-by-resource-type.csv: $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxldedup -t meta+tagspec,meta+hash \
	| hxlcount -t meta+tagspec \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-attributes-by-resource-type.csv: $(EXPANDED_DATA)
	. $(VENV) && cat $(EXPANDED_DATA) \
	| hxldedup -t meta+attribute,meta+hash \
	| hxlcount -t meta+attribute \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-resource-type.csv: $(EXPANDED_DATA)
	. $(VENV) && cat $(EXPANDED_DATA) \
	| hxldedup -t meta+tag,meta+attribute,hash \
	| hxlcount -t meta+tag,meta+attribute \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-hashtags-by-org.csv: $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxldedup -t meta+tag,org \
	| hxlcount -t meta+tag \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-tagspecs-by-org.csv: $(HASHTAG_DATA)
	. $(VENV) && cat $(HASHTAG_DATA) \
	| hxldedup -t meta+tagspec,org \
	| hxlcount -t meta+tagspec \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-attributes-by-org.csv: $(EXPANDED_DATA)
	. $(VENV) && cat $(EXPANDED_DATA) \
	| hxldedup -t meta+attribute,org \
	| hxlcount -t meta+attribute \
	| hxlsort -r -t meta+count \
	> $@

$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-org.csv: $(EXPANDED_DATA)
	. $(VENV) && cat $(EXPANDED_DATA) \
	| hxldedup -t meta+tag,meta+attribute,org \
	| hxlcount -t meta+tag,meta+attribute \
	| hxlsort -r -t meta+count \
	> $@

# Admin

$(VENV):
	rm -rf venv && python3 -m venv venv && . $(VENV) && pip3 install -r requirements.txt

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

sync:
	git checkout main && git pull origin main && git push origin main

clean-all: clean-reports clean-venv

clean-reports:
	rm -f $(REPORTS)

clean-venv:
	rm -rf venv

