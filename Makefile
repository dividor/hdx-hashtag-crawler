VENV=venv/bin/activate
OUTPUT_DIR=output
DATA=$(OUTPUT_DIR)/hdx-hashtag-stats.csv
SCRIPT=crawl-hdx.py

run: $(DATA)

$(DATA): $(VENV) $(SCRIPT)
	. $(VENV) && mkdir -p $(OUTPUT_DIR) && python3 $(SCRIPT) > $@

$(VENV):
	rm -rf venv && python3 -m venv venv && pip3 install -r requirements.txt

clean:
	rm -rf venv

real-clean: clean
	rm -rf output && mkdir output
