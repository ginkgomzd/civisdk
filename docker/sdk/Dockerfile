ARG FROM_IMAGE=civisdk/php:latest
FROM ${FROM_IMAGE}

# NB: arguments are scoped by build-stage
# so the following args must be declared after FROM

ARG LOGIN_UID=1000
ARG LOGIN_GID=${LOGIN_UID}
ARG USER_NAME=cividev

# NB: less is required by wp-cli
# leaving-out sudo because: why are you doing sysadmin inside a container?

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt-get update
RUN apt-get install -y --no-install-recommends \
  bash-completion \
  default-mysql-client \
  git \
  less \
  nano \
  nodejs \
  rsync \
  sudo \
  unzip \
  vim \
  zip \
  && rm -r /var/lib/apt/lists/*

RUN addgroup --gid=$LOGIN_GID $USER_NAME
RUN useradd --create-home --uid ${LOGIN_UID} --gid ${LOGIN_GID} \
  --home-dir /home/${USER_NAME} ${USER_NAME}
COPY sudo /etc/sudoers.d/${USER_NAME}

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

CMD ["/bin/bash", "--login"]