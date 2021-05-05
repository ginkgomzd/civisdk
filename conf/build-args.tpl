
export GD_OPTS_PRE_74 ?= {{GD_OPTS_PRE_74}}# docker-php-ext-configure gd options for < 7.4
export GD_OPTS_POST_74 ?= {{GD_OPTS_POST_74}}# docker-php-ext-configure gd options for >= 7.4
export HOST_IP ?= {{HOST_IP}}# docker container host IP
export LOGIN_UID ?= {{LOGIN_UID}}# match container UID to ease use of bind-mounts
export LOGIN_GID ?= {{LOGIN_GID}}# match container GID to ease use of bind-mounts
