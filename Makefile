.DELETE_ON_ERROR:
export PATH := ./node_modules/.bin:$(PATH)

BUILD_DIR = ./build
SRC_DIR = ./src
DEV_DIR = $(BUILD_DIR)/dev
DIST_DIR = $(BUILD_DIR)/dist
NAME = static

SRC_ALL_SCRIPT := $(shell find $(SRC_DIR) -name '*.js')
SRC_MAIN_SCRIPT := $(shell find $(SRC_DIR) -name 'main.js')

SRC_ALL_STYLE := $(shell find $(SRC_DIR) -name '*.less')
SRC_MAIN_STYLE := $(shell find $(SRC_DIR) -name 'main.less')

SRC_ALL_MARKUP := $(shell find $(SRC_DIR) -name '*.md' -o -name '*.html')

DEV_MAIN_SCRIPT := $(patsubst $(SRC_DIR)/%,$(DEV_DIR)/%,$(SRC_MAIN_SCRIPT))
DEV_MAIN_STYLE := $(patsubst $(SRC_DIR)/%.less,$(DEV_DIR)/%.css,$(SRC_MAIN_STYLE))

DIST_MAIN_SCRIPT := $(patsubst $(SRC_DIR)/%,$(DIST_DIR)/%,$(SRC_MAIN_SCRIPT))
DIST_MAIN_STYLE := $(patsubst $(SRC_DIR)/%.less,$(DIST_DIR)/%.css,$(SRC_MAIN_STYLE))

# Create a distribution archive
.PHONY: package
package: clean-dist dist
	tar --exclude='.?*' -czf $(NAME).tgz -C $(DIST_DIR) .

.PHONY: clean-dist
clean-dist: clean-dev
	@rm -rf $(DIST_DIR)

.PHONY: clean-dev
clean-dev:
	@rm -rf $(DEV_DIR)


# Install Node based dependencies
node_modules/.install: package.json
	@npm install
	@touch $@


# Tasks for running in dev mode
.PHONY: dev
dev: $(DEV_MAIN_SCRIPT) $(DEV_MAIN_STYLE) $(DEV_DIR)/.markup dev-assets

$(DEV_DIR)/%.js: $(SRC_ALL_SCRIPT) node_modules/.install
	@mkdir -p $(dir $@)
	@browserify --debug $(patsubst $(DEV_DIR)/%,$(SRC_DIR)/%,./$@) > $@

$(DEV_DIR)/%.css: $(SRC_ALL_STYLE) node_modules/.install
	@mkdir -p $(dir $@)
	@lessc --source-map-less-inline --source-map-map-inline \
			--source-map-rootpath=$(SRC_DIR) \
			$(patsubst $(DEV_DIR)/%.css,$(SRC_DIR)/%.less,./$@) | autoprefixer --output $@

$(DEV_DIR)/.markup: $(SRC_ALL_MARKUP)
	@hymark $(SRC_DIR) $(DEV_DIR) --engine=handlebars --templates=$(SRC_DIR)/_templates
	@touch $@

.PHONY: dev-assets
dev-assets:
	@rsync --recursive --update --perms --executability $(SRC_DIR)/assets $(DEV_DIR)


# Tasks for running in dist mode
.PHONY: dist
dist: $(DIST_MAIN_SCRIPT) $(DIST_MAIN_STYLE) $(DIST_DIR)/.markup dist-assets

$(DIST_DIR)/%.js: $(DEV_DIR)/%.js
	@mkdir -p $(dir $@)
	@uglifyjs $< > $@

$(DIST_DIR)/%.css: $(SRC_ALL_STYLE) node_modules/.install
	@mkdir -p $(dir $@)
	@lessc --clean-css $(patsubst $(DIST_DIR)/%.css,$(SRC_DIR)/%.less,./$@) | autoprefixer --output $@

$(DIST_DIR)/.markup: $(SRC_ALL_MARKUP)
	@hymark $(SRC_DIR) $(DIST_DIR) --engine=handlebars --templates=$(SRC_DIR)/_templates
	@touch $@

.PHONY: dist-assets
dist-assets:
	@rsync --recursive --update --perms --executability $(SRC_DIR)/assets $(DIST_DIR)
