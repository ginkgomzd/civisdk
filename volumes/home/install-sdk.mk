
NODE_BINS := \
	node_modules/bower/bin/bower \
	node_modules/karma/bin/karma \
	node_modules/jshint/bin/jshint \
	node_modules/phantomjs-prebuilt/bin/phantomjs \
	node_modules/protractor/bin/protractor \
	node_modules/protractor/bin/webdriver-manager \
	node_modules/grunt-cli/bin/grunt

# mostly used to clean-up:
PHAR_BINS := \
	_codecept-php5.phar _codecept-php7.phar \
	box \
	civici \
	civistrings \
	civix \
	cv \
	composer \
	drush \
	git-scan \
	phpunit4 phpunit5 phpunit6 phpunit7 \
	pogo \
	wp

# # #
# Default: install it!
install: install-sdk

bin:
	mkdir $@

bin/composer: bin
	$(MAKE) -f composer.mk INSTALL_PATH='./bin'
	touch $@

define BASHRC_PATH :=

PATH="/home/$$(whoami)/bin:$${PATH}"

endef

.bashrc: export BASHRC_PATH
.bashrc:
	echo "$$BASHRC_PROFILE" > $@

.drush/commands:
	mkdir -p $@

package.json:
	curl -L -o $@ \
	https://raw.githubusercontent.com/civicrm/civicrm-buildkit/master/package.json

install-sdk: package.json bin/composer composer.json .bashrc .drush/commands bin/joomla
	composer install # --no-cache
	-composer validate
	-drush init -y && drush cc drush
	npm install
	cd bin && \
	$(foreach pkg, ${NODE_BINS}, \
		if [ -f "../${pkg}" ]; then \
			test -L $(notdir ${pkg}) || ln -s ../${pkg} $(notdir ${pkg}); fi;)
	chmod a+x ${NODE_BINS}

.joomla-cli: JOOMLA_CLI_VER ?= 1.6.0
.joomla-cli:
	curl -L -o joomla-cli.zip \
	https://github.com/joomlatools/joomlatools-console/archive/refs/tags/v${JOOMLA_CLI_VER}.zip
	unzip joomla-cli.zip && rm joomla-cli.zip
	mv joomlatools-console-${JOOMLA_CLI_VER} $@	

bin/joomla: .joomla-cli | bin/composer
	cd .joomla-cli && \
	composer install
	cd bin && ( test -L joomla || ln -s ../.joomla-cli/bin/joomla )

# # #
# Clean

define unlink
	- unlink $1;

endef
define rm
	- rm -f $1;

endef

clean:
	rm -rf  bin vendor node_modules 
	rm -rf .drush/commands/backdrop .joomla-cli bin/joomla \
	.drush .composer .npm .config .bashrc
	$(foreach pkg, ${NODE_BINS}, $(call unlink,bin/$(notdir ${pkg})))
	$(foreach pkg, ${PHAR_BINS}, $(call rm,bin/$(notdir ${pkg})))
