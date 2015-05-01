export PATH := ./node_modules/.bin:$(PATH)

DEV_ENVIRONMENTS := $(shell find . -name 'app.development*' | cut -d '.' -f 3)

PROD_ENVIRONMENTS := $(shell find . -name 'app.production*' | cut -d '.' -f 3)

clean:
	@echo cleaning output folder...
	@roots clean

build-dev: clean
	@echo fetching latest MAMA data...
	@node _query_apis.js
	@echo compiling development environments...
	@for environment in $(DEV_ENVIRONMENTS) ; do \
		echo $$environment ; \
		roots compile -e $$environment ; \
	done
	@echo development
	@roots compile -e development
	@echo ...done!

build: clean
	@echo fetching latest MAMA data...
	@node _query_apis.js
	@echo compiling production environments...
	@for environment in $(PROD_ENVIRONMENTS) ; do \
		echo $$environment ; \
		roots compile -e $$environment ; \
	done
	@echo production
	@roots compile -e production
	@echo ...done!
