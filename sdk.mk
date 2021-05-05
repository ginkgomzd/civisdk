# Setting-up containers on the host.
#
# To add environment variables to the docker-compose context, add make-formatted
# configs to the prerequisite list for the .env target. After editing a
# prerequisite config, run `make .env` to update.
#

run-service = docker-compose run --rm

ifdef NAMESPACE
	# run an images not in the docker-compose.yml:
	run-image = docker run --rm --network ${NAMESPACE}_default
endif

# -include mdo-config.mk

define HELP_TXT

SDK CONTAINERS CLI 

`make` targets that wrap docker-compose

	`up` 		- to start SDK container services
	`down` 		- to stop all SDK container services
	`shell` 	- for a shell with SDK dev tools installed
	`build` 	- runs the default make in app/ inside a "shell" container
	`tail`		- docker-compose logs -f; use the source for "logs" service for Civi/CMS logs.
	`list` 		- to see running containers
	`.env` 		- updated from certain conf/ files (use the source)

See Makefile for other features.
endef

default help:
	$(info $(HELP_TXT))

shell: install
	${run-service} shell

build deploy:
	@$(run-service) shell make -C app

.env: DONT_CARE := $(or $(CONFIG_INCLUDES),$(error Make-Do include unavailable. Try running in the shell container))
.env: conf/env-mysql.conf conf/build-args.conf | set-env-host
	$(eval THEVARS := $(shell cat $^ | $(parse-conf-vars.awk)))
	$(eval export ${THEVARS})
	@truncate -s 0 $@
	@echo '# AUTO-GENERATED: see make recipe for this file' > $@
	@$(foreach v,${THEVARS}, echo '${v}={{${v}}}' | ${REPLACE_TOKENS} >> $@; )
	$(info Generated new $@)

# # #
# provide host IP to docker-compose environment
# primarilty for XDEBUG_CONFIG
set-env-host: HOST_IP=$(shell /sbin/ip route | awk '/default/ { print $$3 }')
set-env-host:
	$(MAKE) conf/build-args.conf-save
.PHONY: set-env-host

up: .env
	docker-compose up -d

down:
	docker-compose down

install: volumes/home/bin

# using as proxy flag for sdk installation
volumes/home/bin:
	@$(run-service) shell make -f install-sdk.mk clean install

re-install:
	@$(run-service) shell make -f install-sdk.mk clean install
