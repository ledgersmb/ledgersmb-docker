# ledgersmb-docker

Dockerfile for LedgerSMB Docker image

# Supported tags

- `1.10`, `1.10.x`, `latest` - Latest official release from the 1.10 branch
- `1.9`, `1.9.30` - Last official release from the 1.9 branch
- `1.8`, `1.8.31` - Last official release from the 1.8 branch (End-of-Life)
- `1.7`, `1.7.41` - Last official release from the 1.7 branch (End-of-Life)
- `1.6`, `1.6.33` - Last official release from the 1.6 branch (End-of-Life)
- `1.5`, `1.5.30` - Last official release from the 1.5 branch (End-of-Life)
- `1.4`, `1.4.42` - Last official release from the 1.4 branch (End-of-Life)
- `master` - Master branch from git, unstable

Containers supporting the development process are provided
through the ledgersmb-dev-docker project. See https://github.com/ledgersmb/ledgersmb-dev-docker/blob/master/README.md#getting-started.

# What is LedgerSMB?

LedgerSMB is a user-friendly accounting and ERP solution for small to
mid-size businesses. It comes with support for many languages and support
for different locales.

The project aims to be the solution a start-up never outgrows.


# How is this image designed to be used?

This image is designed to be used in conjunction with a running PostgreSQL
instance (such as may be provided through a separate image).

This image exposes port 5762 running a Starman HTTP application server. We
do recommend not exposing this port publicly, because

1. The Starman author recommends not exposing it
2. We strongly recommend TLS encryption of all application traffic

While the exposed port can be used for quick evaluation, it's recommended
to add the TLS layer by applying Nginx or Apache as reverse proxy.

Enabling optional functionalities such as outgoing e-mail and printing
could require additional setup of a mail service or CUPS printer service.

# How to use this image

This image can be installed either automatically with the Docker compose file
or manually with docker only.

## Docker-Compose: Installation and start

This image provides `docker-compose.yml` which can be used to pull related
images, install them, establish an internal network for their communications,
adjust environment variables, start and stop LedgerSMB. The only instructions
required, after the optional edition of the file to adjust the environment
variables, are:

```plain
 $ docker-compose pull
 $ docker-compose up -d
```

Or use the following to set a different password and/or parallel processing
capacity (so called 'workers'):

```plain
 $ docker-compose pull
 $ POSTGRES_PASSWORD=def \
   LSMB_WORKERS=10 \
   docker-compose up -d
```

This will set up two containers: (1) a PostgreSQL container with persistent
storage which is retained between container updates and (2) a LedgerSMB
container configured to connect to the PostgreSQL container as its database
server. Your LedgerSMB installation should now be accessible through
[http://localhost:5762/](http://localhost:5762/).

The default number of workers is 5. The default database username and password
are:

```plain
   username: postgres
   password: abc
```

From here, follow the steps as detailed in the instructions for
[preparing for first use](https://ledgersmb.org/content/preparing-ledgersmb-19-first-use).

## Manual installation

This section assumes availability of a PostgreSQL server to attach to the
LedgerSMB image as the database server.

### Start LedgerSMB

```plain
 $ docker run -d -p 5762:5762 --name myledger \
              -e POSTGRES_HOST=<ip/hostname> ledgersmb/ledgersmb:latest
```

This command maps port 5762 of your container to port 5762 in your host. The
web application inside the container should now be accessible through
http://localhost:5762/setup.pl and http://localhost:5762/login.pl.

Below are more variables which determine container configuration,
like `POSTGRES_HOST` above.

# Set up LedgerSMB

 * Visit http://localhost:5762/setup.pl.
 * Log in with the "postgres" user and the password `abc` as given above -
   or with the credentials of your own database server in case of a manual
   setup - and provide the name of a company (= database name) you want to
   create.
 * Go over the steps presented in the browser

Once you have completed the setup steps, you have a fully functional
LedgerSMB instance running!

Visit http://localhost:5762/login.pl to log in and get started.

# Updating the LedgerSMB container

No persistant data is stored in the LedgerSMB container.

All LedgerSMB data is stored in PostgreSQL, so you can stop/destroy/run a
new LedgerSMB container as often as you want.

In case of the Docker Compose setup, all PostgreSQL data is stored on the
Docker volume with the name ending in `_pgdata`. This volume is not destroyed
when updating the containers; only explicit removal destroys the data.

# Environment Variables

The LedgerSMB image uses several environment variables. They are all optional.


## `POSTGRES_HOST`

Default: postgres

Specifies the hostname of the PostgreSQL server to connect to. If you use
a PostgreSQL image, set it to the name of that image.

## `POSTGRES_PORT`

Default: 5432

Port on which the PostgreSQL server is running.

## `DEFAULT_DB`

Default: lsmb

Set this if you want to automatically log in to a particular LedgerSMB database
without needing to enter the name of that database on the login.pl login screen.

## `LSMB_WORKERS`

Default: 5

Set this if you want to run in a memory-constrained environment. E.g. set it to
2 when running in a 1 GB memory setup. Please do note that this may adversely
affect the performance experience of users.

## Mail configuration

As of 1.8.0, the image is based on Debian Buster instead of Debian Stretch;
with Buster, the `ssmtp` program has been removed from Debian, this image
had to change strategy. The main application always came with built-in e-mail
yet with the deprecation, the abilities have expanded.

The following parameters are now supported to set mail preferences:

* `LSMB_MAIL_SMTPHOST`
* `LSMB_MAIL_SMTPPORT`
* `LSMB_MAIL_SMTPTLS`
* `LSMB_MAIL_SMTPSENDER_HOSTNAME`
* `LSMB_MAIL_SMTPUSER`
* `LSMB_MAIL_SMTPPASS`
* `LSMB_MAIL_SMTPAUTHMECH`

# Advanced setup

## Docker Compose with reverse proxy

The `docker-compose-reverseproxy.yml` file shows a docker-compose setup
which adds an Nginx reverse proxy configuration on top of the base
`docker-compose.yml` configuration file. If the content of this repository
is cloned into the current directory (`git clone https://github.com/ledgersmb/ledgersmb-docker.git ; cd ledgersmb-docker`), it can be used as:

```plain
 $ docker-compose \
    -f docker-compose.yml \
    -f docker-compose-reverseproxy.yml \
       up -d
```

This setup can be used in combination with an image which runs the
Certbot certificate renewal process *and* Nginx to do TLS termination. The
default reverse proxy is mostly an example; it publishes on
[http://localhost:8080/](http://localhost:8080/).

An example of such an image can be found at
[https://github.com/jonasalfredsson/docker-nginx-certbot](https://github.com/jonasalfredsson/docker-nginx-certbot),
which is published on Docker Hub as
[jonasal/nginx-certbot](https://hub.docker.com/r/jonasal/nginx-certbot).

**Upgrade note** When upgrading this setup, please remove the volume ending
in `_lsmbdata` before starting the upgraded containers. Without that, the
webcontent won't be upgraded! E.g.:

```plain
  $ docker-compose \
      -f docker-compose.yml \
      -f docker-compose-reverseproxy.yml \
        rm -s -f -v && \
    docker volume rm ledgersmb-docker_lsmbdata && \
    docker-compose \
      -f docker-compose.yml \
      -f docker-compose-reverseproxy.yml \
        pull && \
    docker-compose \
      -f docker-compose.yml \
      -f docker-compose-reverseproxy.yml \
        up -d
```

# Troubleshooting/Developing

Currently the LedgerSMB installation is in /srv/ledgersmb
and the startup & config script is /usr/bin/start.sh.


# User Feedback

## Issues

If you have any problems with or questions about this image or LedgerSMB,
please contact us on the [mailing list](http://ledgersmb.org/topic/support/mailing-lists-rss-and-nntp-feeds)
or through a [GitHub issue](https://github.com/ledgersmb/ledgersmb-docker/issues).

You can also reach some of the official LedgerSMB maintainers via the
[Matrix](https://matrix.org) room in [#ledgersmb:matrix.org](https://matrix.to/#/#ledgersmb:matrix.org).
The [Element](https://app.element.io/#/room/#ledgersmb:matrix.org) Matrix client is highly recommended.


## Contributing

You are invited to contribute new features, fixes, or updates, large or small;
we are always thrilled to receive pull requests, and do our best to process
them as fast as we can.
