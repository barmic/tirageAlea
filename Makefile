.PHONY: all clean

all: dist/tiragealea.js dist/index.html dist/tirage.css

dist/tiragealea.js: $(wildcard src/*.elm)
	mkdir -p dist && elm make $^ --output=$@

dist/index.html: assets/tiragealea1.html
	mkdir -p dist && cp $^ $@

dist/tirage.css: assets/tirage.css
	mkdir -p dist && cp $^ $@

clean:
	rm -rf dist