# Setting-up containers on the host.
#
# To add environment variables to the docker-compose context, add make-formatted
# configs to the prerequisite list for the .env target. After editing a
# prerequisite config, run `make .env` to update.
#

run-service = docker-compose run --rm

#
# YAGNI, but I can't help maself
#
ifdef NAMESPACE
	# run an images not in the docker-compose.yml:
	run-image = docker run --rm --network ${NAMESPACE}_default
endif

#
# only required when working with config files:
# see validation in .env recipe for how to safely use
# will be available in the configure-sdk dk-cmp service
-include mdo-config.mk

define HELP_TXT

SDK CONTAINERS CLI 

`make` targets that wrap docker-compose

	`up` 		- to start SDK container services
	`down` 		- to stop all SDK container services
	`shell` 	- for a shell with SDK dev tools installed
	`build` 	- runs the default make in app/ inside a "shell" container
	`tail`		- docker-compose logs -f; use the source for "logs" service for Civi/CMS logs.
	`list` 		- to see running containers

INSTALL:
	`configure` - interactive setup to generate the .env [WIP - see TODO:]
	`.env` 		- updated from certain conf/ files (use the source)

See Makefile for other features.
endef

default help:
	$(info $(HELP_TXT))

shell: install
	${run-service} shell

build deploy:
	@$(run-service) shell make -C app

.env: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the shell container))
.env: conf/env-mysql.conf conf/build-args.conf | set-env-host set-env-uid-gid
	$(eval THEVARS := $(shell cat $^ | $(parse-conf-vars.awk)))
	$(eval export ${THEVARS})
	@truncate -s 0 $@
	@echo '# AUTO-GENERATED: see make recipe for this file' > $@
	@$(foreach v,${THEVARS}, echo '${v}={{${v}}}' | ${REPLACE_TOKENS} >> $@; )
	$(info Generated new $@)

# # #
# provide host IP to docker-compose environment
# primarilty for XDEBUG_CONFIG
set-env-host: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the shell container))
set-env-host: HOST_IP=$(shell /sbin/ip route | awk '/default/ { print $$3 }')
set-env-host:
	@$(MAKE) -s conf/build-args.conf-save
.PHONY: set-env-host

set-env-uid-gid: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the shell container))
set-env-uid-gid: LOGIN_UID=$(shell id -u)
set-env-uid-gid: LOGIN_GID=$(shell id -g)
set-env-uid-gid:
	@$(MAKE) -s conf/build-args.conf-save
.PHONY: set-env-host

#
# TODO: some kind of buffering is hobbling interactive config.
# does not work even not as a sub-sub-shell (make > dk-cmp run > make > sh -c awk...)
# so, maybe an awk problem? https://www.gnu.org/software/gawk/manual/html_node/I_002fO-Functions.html
#
configure: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the shell container))
configure:
	${run-service} make-do reconfigure .env

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
