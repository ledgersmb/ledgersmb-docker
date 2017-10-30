# ledgersmb-docker
Dockerfile for LedgerSMB Docker image

# Supported tags

- `1.5`, `1.5.x`, `latest` - Latest release tarball from 1.5 branch
- `1.4`, `1.4.x` - Latest tagged release of git 1.4 branch
- `master` - Master branch from git, unstable
- `master-dev`, `1.5-dev` - Containers to kick off a development setup


# What is LedgerSMB?

LedgerSMB is a user-friendly accounting and ERP solution for small to
mid-size businesses. It comes with support for many languages and support
for different locales.

The project aims to be the solution a start-up never outgrows.


# How is this image designed to be used?

This image is designed to be used in conjunction with a running PostgreSQL
instance (such as may be provided through a separate image).

This image exposes port 5762 running a Starman HTTP application server. We
do not recommend exposing this port publicly, because

1. The Starman author recommends it
2. We strongly recommend TLS encryption of all application traffic

While the exposed port can be used for quick evaluation, it's recommended
to add the TLS layer by applying Nginx or Apache as reverse proxy.

Enabling optional functionalities such as outgoing e-mail and printing
could require additional setup of a mail service or CUPS printer service.

# How to use this image

## Start a postgres instance

```plain
 $ docker run -d --name postgres \
              -e POSTGRES_PASSWORD=mysecretpassword \
              postgres:latest
```

BEWARE: The command above creates a container with the database data stored
*inside* the container. Upon removal of the container, the database data will
be removed too!

To prevent destruction of the database data upon replacement of the container,
please use these commands instead:

```plain
 $ docker volume create dbdata
 $ docker run -d --name postgres \
              -e POSTGRES_PASSWORD=mysecretpassword \
              -e PGDATA=/var/lib/postgresql/data/pgdata \
              -v dbdata:/var/lib/postgresql/data \
              postgres:latest
```

## Start LedgerSMB

```plain
 $ docker run -d -p 5762:5762 --name myledger \
              ledgersmb/ledgersmb:latest
```

This command maps port 5762 of your container to port 5762 in your host. The
web application inside the container should now be accessible through
http://localhost:5762/setup.pl.

## Set up LedgerSMB

 * Visit http://myledger:5762/setup.pl.
 * Log in with the "postgres" user and the password `mysecretpassword`
   and provide the name of a company (= database name) you want to create.
 * Go over the steps presented in the browser

Once you have completed the setup steps, you have a fully functional
LedgerSMB instance running!

Visit http://localhost:5762/login.pl to log in and get started.

# Updating the LedgerSMB container

No persistant data is stored in the LedgerSMB container.

All LedgerSMB data is stored in Postgres, so you can stop/destroy/run a
new LedgerSMB container as often as you want.

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

## Mail configuration

* `SSMTP_ROOT`
* `SSMTP_MAILHUB`
* `SSMTP_HOSTNAME`
* `SSMTP_USE_STARTTLS`
* `SSMTP_AUTH_USER`
* `SSMTP_AUTH_PASS`
* `SSMTP_METHOD`
* `SSMTP_FROMLINE_OVERRIDE`

These variables are used to set outgoing SMTP defaults.

To set the outgoing email address, set `SSMTP_ROOT` and `SSMTP_HOSTNAME` at
a minimum.

`SSMTP_MAILHUB` defaults to the default docker0 interface, so if your host is
already configured to relay mail, this should relay successfully with only
the root and hostname set.

Use the other environment variables to relay mail through a different host.

# Troubleshooting/Developing

Currently the LedgerSMB installation is in /srv/ledgersmb
and the startup & config script is /usr/bin/start.sh.


# User Feedback

## Issues

If you have any problems with or questions about this image or LedgerSMB, please contact us on the [mailing list](http://ledgersmb.org/topic/support/mailing-lists-rss-and-nntp-feeds) or through a [GitHub issue](https://github.com/ledgersmb/ledgersmb-docker/issues).

You can also reach some of the official LedgerSMB maintainers via the `#ledgersmb` IRC channel on [Freenode](https://freenode.net), or on the bridged [Matrix](https://matrix.org) room in [#ledgersmb:matrix.org](https://matrix.to/#/#ledgersmb:matrix.org). The [Vector.im](https://vector.im/beta/#/room/#ledgersmb:matrix.org) Matrix client is highly recommended.


## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.
