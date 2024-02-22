VENV=venv/bin/activate
OUTPUT_DIR=output
HASHTAG_SCRIPT=crawl-hdx.py
HASHTAG_DATA=$(OUTPUT_DIR)/hdx-hashtag-stats.csv
EXPANDED_SCRIPT=expand-data.py
EXPANDED_DATA=$(OUTPUT_DIR)/hdx-expanded-stats.csv
CKAN_TAG_SCRIPT=ckan-tags.py
CKAN_TAG_DATA=$(OUTPUT_DIR)/hxl-ckan-tags.csv
QUICKCHARTS_SCRIPT=quick-charts.py
QUICKCHARTS_DATASETS=$(OUTPUT_DIR)/hxl-quickcharts.csv
DATASET_HASHED_DATA=$(OUTPUT_DIR)/hdx-expanded-hashed-stats.csv
DATASET_LIST=$(OUTPUT_DIR)/hdx-hxl-dataset-list.csv

RESOURCE_PATTERN_DATA=$(OUTPUT_DIR)/resource-patterns.csv

REPORTS=$(OUTPUT_DIR)/report-resources-by-org.csv \
	$(OUTPUT_DIR)/report-resource-patterns-by-org.csv \
	$(OUTPUT_DIR)/report-resource-pattern-ratio-by-org.csv \
	$(OUTPUT_DIR)/report-resource-patterns-by-ckan-tag.csv \
        $(OUTPUT_DIR)/report-resource-patterns-by-hashtag.csv \
	$(OUTPUT_DIR)/report-resource-patterns-by-attribute.csv \
	$(OUTPUT_DIR)/report-resource-patterns-by-tagspec.csv \
	$(OUTPUT_DIR)/report-resource-patterns-by-hashtag-attribute-pair.csv \
	$(OUTPUT_DIR)/report-orgs-by-hashtag.csv \
	$(OUTPUT_DIR)/report-orgs-by-attribute.csv \
	$(OUTPUT_DIR)/report-orgs-by-tagspec.csv \
	$(OUTPUT_DIR)/report-orgs-by-hashtag-attribute-pair.csv

all: hashtag-data ckan-tags quickcharts-datasets

hashtag-data: $(HASHTAG_DATA)

expanded-data: $(EXPANDED_DATA)

dataset-hashed-data: $(DATASET_HASHED_DATA)

ckan-tags: $(CKAN_TAG_DATA)

quickcharts-datasets: $(QUICKCHARTS_DATASETS)

dataset-list: $(DATASET_LIST)

resource-pattern: $(RESOURCE_PATTERN_DATA)

reports: $(REPORTS)

refresh-venv: clean-venv $(VENV)

#
# Raw source datasets
#

# Generate hashtag data from HDX (takes over a day to run)
$(HASHTAG_DATA): $(VENV) $(HASHTAG_SCRIPT)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& python3 $(HASHTAG_SCRIPT) \
		> $@

# Generate information on datasets with Quick Charts (will be rolled into main script later)
$(QUICKCHARTS_DATASETS): $(VENV) $(QUICKCHARTS_SCRIPT)
	mkdir -pv $(OUTPUT_DIR)
	. $(VENV)  && python3 $(QUICKCHARTS_SCRIPT) \
		> $@

# Expand the hashtag data to use a separate row for each attribute
$(EXPANDED_DATA): $(VENV) $(EXPANDED_SCRIPT) $(HASHTAG_DATA) $(QUICKCHARTS_DATASETS)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| python3 $(EXPANDED_SCRIPT) \
		| hxlmerge -m $(QUICKCHARTS_DATASETS) -k meta+dataset -t meta+has_quickcharts \
		> $@

# Generate information on CKAN tags applied to HXLated datasets
$(CKAN_TAG_DATA): $(VENV) $(CKAN_TAG_SCRIPT) $(DATASET_HASHED_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& python3 $(CKAN_TAG_SCRIPT) \
		| hxlmerge -k meta+dataset -t meta+hash -m $(DATASET_HASHED_DATA) \
		> $@

# Produce resource-pattern data that's hashed at the resource level
$(RESOURCE_PATTERN_DATA): $(VENV) $(HASHTAG_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxlcut -i meta+dataset,meta+hash \
		| hxlsort -t meta+hash \
		| hxldedup -t meta+dataset \
		> $@

# Produce resource-pattern data that's hashed at the dataset level (for CKAN tags)
$(DATASET_HASHED_DATA): $(VENV) $(EXPANDED_DATA) $(RESOURCE_PATTERN_DATA)
	mkdir -pv $(OUTPUT_DIR) \
	&& . $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxlcut -x meta+hash \
		| hxlmerge -m $(RESOURCE_PATTERN_DATA) -k meta+dataset -t meta+hash \
		> $@

#
# Reports
#

$(OUTPUT_DIR)/report-resources-by-org.csv: $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t org+provider,meta+resource \
		| hxlcount -t org+provider -a "count(org+provider) as Resources#indicator+resources+num" \
		| hxlsort -r -t indicator+resources+num \
		> $@

$(OUTPUT_DIR)/report-resource-patterns-by-org.csv: $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t org+provider,meta+hash \
		| hxlcount -t org+provider -a "count(org+provider) as Resource patterns#indicator+resource_patterns+num" \
		| hxlsort -r -t indicator+resource_patterns+num \
		> $@

$(OUTPUT_DIR)/report-resource-pattern-ratio-by-org.csv: $(OUTPUT_DIR)/report-resources-by-org.csv $(OUTPUT_DIR)/report-resource-patterns-by-org.csv $(VENV)
	. $(VENV) \
	&& cat $< \
		| hxlmerge -m output/report-resource-patterns-by-org.csv -k org+provider -t indicator+resource_patterns+num \
		| hxladd -s "Pattern:resource ratio#indicator+pattern_resource_ratio+num={{#indicator+resource_patterns+num/#indicator+resources+num}}" \
		| hxlcut -i org+provider,indicator+ratio \
		| hxlsort -t org+provider \
		| hxlsort -r -t indicator+ratio \
		> $@

$(OUTPUT_DIR)/report-resource-patterns-by-ckan-tag.csv: $(CKAN_TAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(CKAN_TAG_DATA) \
		| hxldedup -t org+provider,meta+tag,meta+hash \
		| hxlcount -t meta+tag -a "count(meta+tag) as Resource patterns#indicator+resource_patterns+num" \
		| hxlsort -r -t indicator+resource_patterns+num \
		> $@

$(OUTPUT_DIR)/report-resource-patterns-by-hashtag.csv: $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tag,org,meta+hash \
		| hxlcount -t meta+tag -a "count(meta+tag) as Resource patterns#indicator+resource_patterns+num" \
		| hxlsort -r -t indicator+resource_patterns+num \
		> $@

$(OUTPUT_DIR)/report-resource-patterns-by-attribute.csv: $(EXPANDED_DATA) $(VENV)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxlselect -r -q 'meta+attribute=+' \
		| hxldedup -t meta+attribute,org,meta+hash \
		| hxlcount -t meta+attribute -a "count(meta+attribute) as Resource patterns#indicator+resource_patterns+num" \
		| hxlsort -r -t indicator+resource_patterns+num \
		> $@

$(OUTPUT_DIR)/report-resource-patterns-by-tagspec.csv: $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tagspec,org,meta+hash \
		| hxlcount -t meta+tagspec -a "count(meta+tagspec) as Resource patterns#indicator+resource_patterns+num" \
		| hxlsort -r -t indicator+resource_patterns+num \
		> $@

$(OUTPUT_DIR)/report-resource-patterns-by-hashtag-attribute-pair.csv: $(EXPANDED_DATA) $(VENV)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxlselect -r -q 'meta+attribute=+' \
		| hxldedup -t meta+tag,meta+attribute,org,meta+hash \
		| hxladd -s "Hashtag+attribute pair#meta+pair={{#meta+tag}}{{#meta+attribute}}" \
		| hxlcount -t meta+pair -a "count(meta+pair) as Resource patterns#indicator+resource_patterns+num" \
		| hxlsort -r -t indicator+resource_patterns+num \
		> $@

$(OUTPUT_DIR)/report-orgs-by-hashtag.csv: $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tag,org \
		| hxlcount -t meta+tag -a "count(meta+tag) as Provider orgs#indicator+provider_orgs+num" \
		| hxlsort -r -t indicator+provider_orgs+num \
		> $@

$(OUTPUT_DIR)/report-orgs-by-attribute.csv: $(EXPANDED_DATA) $(VENV)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
		| hxlselect -r -q 'meta+attribute=+' \
		| hxldedup -t meta+attribute,org \
		| hxlcount -t meta+attribute -a "count(meta+attribute) as Provider orgs#indicator+provider_orgs+num" \
		| hxlsort -r -t indicator+provider_orgs+num \
		> $@

$(OUTPUT_DIR)/report-orgs-by-tagspec.csv: $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $(HASHTAG_DATA) \
		| hxldedup -t meta+tagspec,org \
		| hxlcount -t meta+tagspec -a "count(meta+tagspec) as Provider orgs#indicator+provider_orgs+num" \
		| hxlsort -r -t indicator+provider_orgs+num \
		> $@

$(OUTPUT_DIR)/report-orgs-by-hashtag-attribute-pair.csv: $(EXPANDED_DATA) $(VENV)
	. $(VENV) \
	&& cat $(EXPANDED_DATA) \
	        | hxlselect -r -q "#meta+attribute=+" \
		| hxldedup -t meta+tag,meta+attribute,org \
		| hxladd -s "Hashtag+attribute pair#meta+pair={{#meta+tag}}{{#meta+attribute}}" \
		| hxlcount -t meta+pair -a "count(meta+pair) as Provider orgs#indicator+provider_orgs+num" \
		| hxlsort -r -t indicator+provider_orgs+num \
		> $@

$(DATASET_LIST): $(HASHTAG_DATA) $(VENV)
	. $(VENV) \
	&& cat $< \
	        | hxlcut -i meta+dataset,date+created,org+provider \
	        | hxldedup \
                | hxlsort -t date+created,org+provider,meta+dataset \
	        > $@

check-quick-charts: $(OUTPUT_DIR)/datasets-quick-charts.csv $(VENV)

$(OUTPUT_DIR)/datasets-quick-charts.csv: $(DATASET_LIST) check-quick-charts.py $(VENV)
	. $(VENV) \
		&& python3 check-quick-charts.py $< \
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

