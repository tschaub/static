.DELETE_ON_ERROR:
export PATH := ./node_modules/.bin:$(PATH)

BUILD_DIR := ./build
SRC_DIR := ./src
DEV_DIR := $(BUILD_DIR)/dev
DIST_DIR := $(BUILD_DIR)/dist

SRC_ALL_SCRIPT := $(shell find $(SRC_DIR) -name '*.js')
SRC_MAIN_SCRIPT := $(shell find $(SRC_DIR) -name 'main.js')
SRC_ALL_STYLE := $(shell find $(SRC_DIR) -name '*.less')
SRC_MAIN_STYLE := $(shell find $(SRC_DIR) -name 'main.less')
SRC_MARKUP := $(shell find $(SRC_DIR) -name '*.md' -o -name '*.html')
SRC_ASSETS := $(shell find $(SRC_DIR) -name 'assets' -type d)

DEV_MAIN_SCRIPT := $(patsubst $(SRC_DIR)/%,$(DEV_DIR)/%,$(SRC_MAIN_SCRIPT))
DEV_MAIN_STYLE := $(patsubst $(SRC_DIR)/%.less,$(DEV_DIR)/%.css,$(SRC_MAIN_STYLE))
DEV_ASSETS := $(patsubst $(SRC_DIR)/%,$(DEV_DIR)/%,$(SRC_ASSETS))

DIST_MAIN_SCRIPT := $(patsubst $(SRC_DIR)/%,$(DIST_DIR)/%,$(SRC_MAIN_SCRIPT))
DIST_MAIN_STYLE := $(patsubst $(SRC_DIR)/%.less,$(DIST_DIR)/%.css,$(SRC_MAIN_STYLE))
DIST_ASSETS := $(patsubst $(SRC_DIR)/%,$(DIST_DIR)/%,$(SRC_ASSETS))

NAME = $(shell ./node_modules/.bin/json -f package.json name)

# Create a distribution archive
.PHONY: package
package: clean-dist dist node_modules/.install
	tar -czf $(NAME).tgz -C $(DIST_DIR) .

# Install Node based dependencies
node_modules/.install: package.json
	@npm prune
	@npm install
	@npm dedupe
	@touch $@

# Tasks for running in dev mode
.PHONY: dev
dev: $(DEV_MAIN_SCRIPT) $(DEV_MAIN_STYLE) $(DEV_DIR)/.markup $(DEV_ASSETS)

$(DEV_MAIN_SCRIPT): $(SRC_ALL_SCRIPT) node_modules/.install
	@mkdir -p $(dir $@)
	@browserify --debug $(patsubst $(DEV_DIR)/%,$(SRC_DIR)/%,./$@) > $@

$(DEV_MAIN_STYLE): $(SRC_ALL_STYLE) node_modules/.install
	@mkdir -p $(dir $@)
	@lessc --source-map-less-inline --source-map-map-inline \
			--source-map-rootpath=$(SRC_DIR) \
			$(patsubst $(DEV_DIR)/%.css,$(SRC_DIR)/%.less,./$@) | autoprefixer --output $@

$(DEV_DIR)/.markup: $(SRC_MARKUP)
	@hymark $(SRC_DIR) $(DEV_DIR) --engine=handlebars --templates=$(SRC_DIR)/_templates
	@touch $@

.PHONY: $(DEV_ASSETS)
$(DEV_ASSETS):
	@mkdir -p $(dir $@)
	@rsync --recursive --update --perms --executability $(patsubst $(DEV_DIR)/%,$(SRC_DIR)/%,./$@) $(dir $@)

.PHONY: clean-dev
clean-dev:
	@rm -rf $(DEV_DIR)

# Tasks for running in dist mode
.PHONY: dist
dist: $(DIST_MAIN_SCRIPT) $(DIST_MAIN_STYLE) $(DIST_DIR)/.markup $(DIST_ASSETS)

$(DIST_DIR)/%.js: $(DEV_DIR)/%.js
	@mkdir -p $(dir $@)
	@uglifyjs $< > $@

$(DIST_MAIN_STYLE): $(SRC_ALL_STYLE) node_modules/.install
	@mkdir -p $(dir $@)
	@lessc --clean-css $(patsubst $(DIST_DIR)/%.css,$(SRC_DIR)/%.less,./$@) | autoprefixer --output $@

$(DIST_DIR)/.markup: $(SRC_MARKUP)
	@hymark $(SRC_DIR) $(DIST_DIR) --engine=handlebars --templates=$(SRC_DIR)/_templates
	@touch $@

.PHONY: $(DEV_ASSETS)
$(DIST_ASSETS):
	@mkdir -p $(dir $@)
	@rsync --recursive --update --perms --executability $(patsubst $(DIST_DIR)/%,$(SRC_DIR)/%,./$@) $(dir $@)

.PHONY: clean-dist
clean-dist: clean-dev
	@rm -rf $(DIST_DIR)

.PHONY: test
test: node_modules/.install
	@jscs $(SRC_DIR);
	@lessc --lint $(SRC_ALL_STYLE);

.PHONY: start
start: test dev node_modules/.install
	@browser-sync start --config config/browser-sync.js & watchy --watch package.json,src -- make test dev;

# Tasks for provisioning the dev vm
.PHONY: provision
provision: $(HOME)/.apt-get-install-v0.time

$(HOME)/.apt-get-install-v0.time: $(HOME)/.apt-get-update-v0.time
	apt-get install --yes --force-yes --auto-remove nodejs
	@touch $@

# The task below would normally just run `apt-get update`.  The additional work
# is setting up the apt sources list file for Node.
# TODO: confirm that this is still needed when using Trusty
# If the alt repo stuff is not needed, this can become `apt-get update`.
$(HOME)/.apt-get-update-v0.time:
	# `apt-get update` is run by the script below
	curl -sL https://deb.nodesource.com/setup | bash -
	@touch $@
