VENV=venv/bin/activate
OUTPUT_DIR=output
HASHTAG_SCRIPT=crawl-hdx.py
HASHTAG_DATA=$(OUTPUT_DIR)/hdx-hashtag-stats.csv
EXPANDED_SCRIPT=expand-data.py
EXPANDED_DATA=$(OUTPUT_DIR)/hdx-expanded-stats.csv
CKAN_TAG_SCRIPT=ckan-tags.py
CKAN_TAG_DATA=$(OUTPUT_DIR)/hxl-ckan-tags.csv
DATASET_HASHED_DATA=$(OUTPUT_DIR)/hdx-expanded-hashed-stats.csv

DATA_SERIES_DATA=$(OUTPUT_DIR)/data-series.csv

REPORTS=$(OUTPUT_DIR)/report-ckan-tag-count.csv \
        $(OUTPUT_DIR)/report-hashtags-by-data-series.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-data-series.csv \
	$(OUTPUT_DIR)/report-attributes-by-data-series.csv \
	$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-data-series.csv \
	$(OUTPUT_DIR)/report-hashtags-by-org.csv \
	$(OUTPUT_DIR)/report-tagspecs-by-org.csv \
	$(OUTPUT_DIR)/report-attributes-by-org.csv \
	$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-org.csv

all: hashtag-data ckan-tags

hashtag-data: $(HASHTAG_DATA)

expanded-data: $(EXPANDED_DATA)

dataset-hashed-data: $(DATASET_HASHED_DATA)

ckan-tags: $(CKAN_TAG_DATA)

data-series: $(DATA_SERIES_DATA)

reports: $(REPORTS)

#
# Raw source datasets
#

# Generate hashtag data from HDX (takes over a day to run)
$(HASHTAG_DATA): $(VENV) $(HASHTAG_SCRIPT)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& python3 $(HASHTAG_SCRIPT) \
		> $@

# Expand the hashtag data to use a separate row for each attribute
$(EXPANDED_DATA): $(VENV) $(EXPANDED_SCRIPT) $(HASHTAG_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| python3 $(EXPANDED_SCRIPT) \
		> $@

# Generate information on CKAN tags applied to HXLated datasets
$(CKAN_TAG_DATA): $(VENV) $(CKAN_TAG_SCRIPT) $(DATASET_HASHED_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& python3 $(CKAN_TAG_SCRIPT) \
		| hxlmerge -k meta+dataset -t meta+hash -m $(DATASET_HASHED_DATA) \
		> $@

# Produce data-series data that's hashed at the resource level
$(DATA_SERIES_DATA): $(VENV) $(HASHTAG_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxlcut -i meta+dataset,meta+hash \
		| hxlsort -t meta+hash \
		| hxldedup -t meta+dataset \
		> $@

# Produce data-series data that's hashed at the dataset level (for CKAN tags)
$(DATASET_HASHED_DATA): $(VENV) $(EXPANDED_DATA) $(DATA_SERIES_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxlcut -x meta+hash \
		| hxlmerge -m $(DATA_SERIES_DATA) -k meta+dataset -t meta+hash \
		> $@

#
# Reports
#

$(OUTPUT_DIR)/report-ckan-tag-count.csv: $(CKAN_TAG_DATA)
	. $(VENV) \
	&& cat $(CKAN_TAG_DATA) \
		| hxldedup -t org+provider,meta+tag,meta+hash \
		| hxlcount -t meta+tag \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-hashtags-by-data-series.csv: $(HASHTAG_DATA)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tag,org,meta+hash \
		| hxlcount -t meta+tag \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-tagspecs-by-data-series.csv: $(HASHTAG_DATA)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tagspec,org,meta+hash \
		| hxlcount -t meta+tagspec \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-attributes-by-data-series.csv: $(EXPANDED_DATA)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxldedup -t meta+attribute,org,meta+hash \
		| hxlcount -t meta+attribute \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-data-series.csv: $(EXPANDED_DATA)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxldedup -t meta+tag,meta+attribute,org,meta+hash \
		| hxlcount -t meta+tag,meta+attribute \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-hashtags-by-org.csv: $(HASHTAG_DATA)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tag,org \
		| hxlcount -t meta+tag \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-tagspecs-by-org.csv: $(HASHTAG_DATA)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tagspec,org \
		| hxlcount -t meta+tagspec \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-attributes-by-org.csv: $(EXPANDED_DATA)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxldedup -t meta+attribute,org \
		| hxlcount -t meta+attribute \
		| hxlsort -r -t meta+count \
		> $@

$(OUTPUT_DIR)/report-hashtag-attribute-pairs-by-org.csv: $(EXPANDED_DATA)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxldedup -t meta+tag,meta+attribute,org \
		| hxlcount -t meta+tag,meta+attribute \
		| hxlsort -r -t meta+count \
		> $@

#
# Admin
#

# Create the Python3 virtual environment
$(VENV):
	rm -rf venv && python3 -m venv venv && . $(VENV) && pip3 install -r requirements.txt

sync:
	git checkout main && git pull origin main && git push origin main

clean-all: clean-reports clean-venv

clean-reports:
	rm -f $(REPORTS)

clean-venv:
	rm -rf venv

