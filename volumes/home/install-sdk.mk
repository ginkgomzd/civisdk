
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

define BASHRC :=

PATH="/home/$$(whoami)/bin:$${PATH}"

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

endef

.bashrc: export BASHRC
.bashrc:
	echo "$$BASHRC" > $@

define BASH_PROFILE :=

# include .bashrc if it exists
if [ -f "$$HOME/.bashrc" ]; then
    . "$$HOME/.bashrc"
fi

endef

.profile: export BASH_PROFILE
.profile:
	echo "$$BASH_PROFILE" >> $@

define BASH_ALIASES :=

# enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

    export COLOR_AUTO=' --color=auto'
fi

alias ls='ls --color=auto'
alias ll='ls -hal'

###
# Include local customizations
if [ -d ~/.bash_aliases_local ]; then
	for f in ~/.bash_aliases_local/*
	do
		if [ -f "$f" ]; then
			. "$f"
		fi
	done
fi

endef

.bash_aliases: export BASH_ALIASES
.bash_aliases:
	echo "$$BASH_ALIASES" >> $@

.drush/commands:
	mkdir -p $@

package.json:
	curl -L -o $@ \
	https://raw.githubusercontent.com/civicrm/civicrm-buildkit/master/package.json

install-sdk: package.json bin/composer composer.json .bashrc .profile .drush/commands bin/joomla
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
	.drush .composer .npm .config .bashrc .profile
	$(foreach pkg, ${NODE_BINS}, $(call unlink,bin/$(notdir ${pkg})))
	$(foreach pkg, ${PHAR_BINS}, $(call rm,bin/$(notdir ${pkg})))
