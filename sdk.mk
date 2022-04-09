# Setting-up containers on the host.
#
# To add environment variables to the docker-compose context, add make-formatted
# configs to the prerequisite list for the .env target. After editing a
# prerequisite config, run `make .env` to update.
#

run-service = docker-compose run --rm
run-util = docker-compose -f util.docker-compose.yml run --rm

#
# YAGNI, but I can't help maself
#
ifdef NAMESPACE
	# run an image not in the docker-compose.yml:
	run-image = docker run --rm --network ${NAMESPACE}_default
endif

#
# only required when working with config files:
# see validation in .env recipe for how to safely use.
# will be available in the configure-sdk docker-compose service.
-include mdo-config.mk

define HELP_TXT

SDK CONTAINERS CLI 

`make` targets that wrap docker-compose

	`up` 		- to start SDK container services
	`down` 		- to stop all SDK container services
	`shell` 	- for a shell with SDK dev tools installed
	`mysql-root`- invoke mysql-cli with root credentials to MYSQL_HOST container
	`build` 	- runs the default make in app/ inside a "shell" container
	`tail`		- docker-compose logs -f; use the source for "logs" service for Civi/CMS logs.
	`list` 		- available services
	`utils`		- available utility containers from util.docker-compose.yml

INSTALL:
	`configure` - interactive setup to generate the .env [WIP - see TODO:]
	`install`	- initialize the home volume and install the SDK libraries
	`.env` 		- updated from certain conf/ files (use the source)

MULTIPLE DOCKER-COMPOSE FILES:

Manage the default docker-compose.yml as a symbolic link for quick switching.

	`ln-distro`	- create symbolic link to default.docker-compose.yml
	`ln-dev`	- create symbolic link to your custom dev.docker-compose.yml
	`ln-util`	- create symbolic link to sdk utility containers in util.docker-compose.yml

See Makefile for other features.
endef

default help:
	$(info $(HELP_TXT))

shell: install
	${run-util} shell

mysql-root:
	${run-util} mysql-root

build deploy:
	@$(run-util) shell make -C app

.env: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container))
.env: conf/env-mysql.conf conf/build-args.conf | set-env-host set-env-uid-gid
	$(eval THEVARS := $(shell cat $^ | $(parse-conf-vars.awk)))
	$(eval export ${THEVARS})
	@truncate -s 0 $@
	@echo '# AUTO-GENERATED: see make recipe for this file' > $@
	@$(foreach v,${THEVARS}, echo '${v}={{${v}}}' | ${REPLACE_TOKENS} >> $@; )
	$(info Generated new $@)

# # #
# provide host IP to docker-compose environment
# primarily for XDEBUG_CONFIG
set-env-host: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container))
set-env-host: HOST_IP=$(shell /sbin/ip route | awk '/default/ { print $$3 }')
set-env-host:
	@$(MAKE) -s conf/build-args.conf-save

set-env-uid-gid: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container))
set-env-uid-gid: LOGIN_UID=$(shell id -u)
set-env-uid-gid: LOGIN_GID=$(shell id -g)
set-env-uid-gid:
	@$(MAKE) -s conf/build-args.conf-save

#
# TODO: some kind of buffering is hobbling interactive config.
# does not work even not as a sub-sub-shell (make > dk-cmp run > make > sh -c awk...)
# so, maybe an awk problem? https://www.gnu.org/software/gawk/manual/html_node/I_002fO-Functions.html
#
configure: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container))
configure:
	${run-util} make-do reconfigure .env

up: .env
	docker-compose up -d

down:
	docker-compose down

install: volumes/home/bin

list:
	docker-compose config --services

utils:
	docker-compose -f util.docker-compose.yml config --services

# using as proxy flag for sdk installation
volumes/home/bin:
	@$(run-util) shell make -f install-sdk.mk clean install

re-install:
	@$(run-util) shell make -f install-sdk.mk clean install

# # #
# MySQL User and Permissions
# # #

define my_cnf_tpl
[client]
user={{USER}}
password={{PASSWORD}}

endef

conf/my.cnf: $(eval export USER = ${MYSQL_USER})
conf/my.cnf: $(eval export PASSWORD = ${MYSQL_PASSWORD})
conf/my.cnf: $(eval export my_cnf_tpl)
conf/my.cnf: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container.))
conf/my.cnf:
	echo "$${my_cnf_tpl}" | $(REPLACE_TOKENS) > $@

define create_db_user
CREATE USER ${MYSQL_USER}@`%`
endef

create-db-user: $(eval export create_db_user)
create-db-user: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container.))
create-db-user:
	@echo "$$create_db_user" | $(run-util) mysql-root

define set_db_password
ALTER USER ${MYSQL_USER}@`%` IDENTIFIED BY '${MYSQL_PASSWORD}'
endef

set-db-password: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container.))
set-db-password: $(eval export set_db_password)
set-db-password:
	@echo "$$set_db_password" | $(run-util) mysql-root

define set_db_grants
GRANT ALL PRIVILEGES ON `${MYSQL_USER}_%`.* to ${MYSQL_USER}@`%`;
GRANT ALL PRIVILEGES ON `${MYSQL_USER}`.* to ${MYSQL_USER}@`%`;
endef

set-db-grants: VALIDATE := $(or ${CONFIG_INCLUDES},$(error Make-Do include unavailable. Try running in the make-do container.))
set-db-grants: $(eval export set_db_grants)
set-db-grants:
	@echo "$$set_db_grants" | $(run-util) mysql-root

test-mysql-conn:
	$(run-util) mysql-cli

# # #
# Manage multiple docker-compose files by 
# linking different versions to the default docker-compose file name.
# # #

define safe-unlink-compose-file
	@# File is not a link, so back-up
	@#$(or $(shell test -L docker-compose.yml && echo 'TRUE'), $(call backup-compose-file))
	@# File does not exist, or try to remove
	@#$(if $(shell (test -L docker-compose.yml || test -e docker-compose.yml) && echo 'TRUE'), $(shell rm -f docker-compose.yml))
endef

define backup-compose-file
	@# Abort if back-up location already exists
	@#$(and $(shell test -f dev.docker-compose.yml && echo 'ERROR'), \
		$(error Can not back-up docker-compose.yml, aborting))
	@# Back-up, unless the file does not exist
	@#$(or $(shell test ! -e docker-compose.yml && echo 'TRUE'), \
		$(shell mv docker-compose.yml dev.docker-compose.yml && echo 'Backed-up to dev.docker-compose.yml'))
endef

ln-dev:
	$(safe-unlink-compose-file)
	ln -s dev.docker-compose.yml docker-compose.yml

ln-distro:
	$(safe-unlink-compose-file)
	ln -s default.docker-compose.yml docker-compose.yml

ln-util:
	$(safe-unlink-compose-file)
	ln -s util.docker-compose.yml docker-compose.yml
