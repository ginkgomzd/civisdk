# CiviSDK
docker-composition for a CiviCRM development environment with recommended tools

### Install and Set-up

Optionally, for an interactive prompt for configurations, and to dynamically generate a docker-compose `.env` file: install ginkgomzd/make-do. It requires gnu make and gnu awk. Coming soon: a container to complete configuration.

To manually configure: review each .tpl file in `conf/` and create a `.env` file with the same config variables. See the docker-compose documentation on using `.env` files.

Either copy or create a symlink of the `default.docker-compose.yml` so that you have a `docker-compose.yml`. Using a symlink can be convenient if you want to quickly switch between a custom, the default, or the util docker-compose configuration.

The first time you run the shell container, or by calling `make install` explicitly, install-sdk.mk is run to fetch the SDK libraries. This could take some time, and the files will be downloaded to `volumes/home/`.


## Orientation

The "SDK" itself is essentially a docker-compose container-constellation, and a single container to run a shell in that bind-mounts the `volumes/home` directory to the shell-user's home directory. After the SDK install, recommended CiviCRM development tools are fetched and linked within the home bind-mount. The `app/` directory is also bind-mounted in the shell-user's home directory.

This repo defines docker-compose services in default.docker-compose.yml and util.docker-compose.yml. Scripts are written in Gnu Make, and you can search for `Makefile` or files with the extension, `.mk`. Configure docker-

The `Makefile` in the root is for you to write your own utils, and includes some helpers in `sdk.mk`. Run `make` with no other parameters to display the help and list available commands.

Create your app in `/app`. If you build your app with a Makefile, then just clone your repo and run `make build` (in this dir).
It will run `make` in the sdk shell container.

**Use the source, Luke.**

### Containers

Automatically starts the web-server and MySQL server. Additional containers can be started for mysql client session, or an SDK-enabled bash shell.

Coming Soon: proxy-cache; log tailing; file watcher (live-reload);

### Volumes

`volumes/home` is mounted to the shell container and contains the SDK libraries (like: cv, civix, drush, wp-cli...).

Docker-managed volumes are created for `/var/www/html` and mysql data files.

### Config

Configure the docker-compose environment in `conf/build-args.conf`. The `.env` is autogenerated when make detects that one of the config files it depends on are newer. Re-make explicitly with `make .env`. https://docs.docker.com/compose/environment-variables/

The first time you run one of the SDK make targets, you will be prompted to interactively supply environment configs. Chiefly, this is the MySQL configurations needed. Either add additional configurations to `conf/build-args.conf` or add new files. Be sure to add new config files as prerequisites to the `.env` make recipe.

For interactive config support, add new configs to the corresponding `.tpl`. You can add help-text as a comment (shell-comment style) at the end of the line. Try `make add-config` to interactively extend the config-file template (`.tpl`).

## Debugging

The php image is configured with xdebug.

Use `docker-compose logs` to see PHP and MySQL log output. https://docs.docker.com/compose/reference/logs/

## Roadmap

### CMS/Civi Logs

Run a service container that detects the CMS deployed, and locates CiviCRM ConfigAndLog, and tail's those logs.

### Proxy Cache

Speed-up sdk and app builds by caching downloads of external dependencies.


