# CiviSDK
docker-composition for a CiviCRM development environment with recommended tools

### Install

Depends on ginkgomzd/make-do for `make` includes, chiefly to manage configurations.

The first time you run the shell container, or by calling `make install` explicitly, install-sdk.mk is run to fetch the SDK libraries. This could take some time, and the files will be downloaded to `volumes/home/`.

## Use the Source, Luke

`Makefile` in the repo root is a good starting place. Next stop should be `docker-compose.yml`.

## Orientation

Create your app in `/app`. If you build your app with a Makefile, then just clone your repo and run `make build` (in this dir).
It will run `make` in the sdk shell container.

### Containers

Automatically starts the web-server and MySQL server. Additional containers can be started for mysql client session, or an SDK-enabled bash shell.

Coming Soon: proxy-cache; log tailing; file watcher (live-reload);

### Volumes

`volumes/home` is mounted to the shell container and contains the SDK libraries (like: cv, civix, drush, wp-cli...).

Docker-managed volumes are created for `/var/www/html` and mysql data files.

## Config

Configure the docker-compose environment in `conf/build-args.conf`.




