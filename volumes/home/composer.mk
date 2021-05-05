
CHECK_SHA384 := $(shell curl -L -o - https://composer.github.io/installer.sig)
INSTALL_PATH ?= ./bin

all: install clean-up

.PHONY: install
install: verify install-composer.php
	php install-composer.php --install-dir=$(realpath ${INSTALL_PATH}) --filename=composer

install-composer.php:
		curl -L -o 'install-composer.php' https://getcomposer.org/installer

check.sha384:
	echo $(CHECK_SHA384) install-composer.php > check.sha384

.PHONY: verify
verify: check.sha384 install-composer.php
	sha384sum -c check.sha384

.PHONY: clean-up
clean-up:
	rm check.sha384
	rm install-composer.php
