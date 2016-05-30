# ledgersmb-docker - EXPERIMENTAL
Dockerfile for LedgerSMB Docker image

This is a work in progress to make a docker image for running LedgerSMB. It should not be relied upon for production use!

# Supported tags and respective `Dockerfile` links

-	`dev-master` - Master branch from git, unstable
- `1.5`, `1.5.x` - Latest release tarball from 1.5 branch
- `1.4`, `latest` - Latest tagged release of git 1.4 branch


# What is LedgerSMB?
The LedgerSMB project's priority is to provide an extremely capable yet user-friendly accounting and ERP solution to small to mid-size businesses in all locales where there is interest in using the software. The focus on small to mid-size businesses offers an opportunity to provide a positive user experience in ways which are not present in larger organizations. LedgerSMB ought to strive to be both the ideal SMB accounting/ERP package and also a solution that a start-up will never outgrow. The goals mentioned above will help us provide this ideal solution by allowing us to focus both on technical architecture and on user experience.


# How is this image designed to be used?

This Docker image is built to provide a self-contained LedgerSMB instance. To be functional, you need to connect it to a running Postgres installation. The official Postgres container will work as is, if you link it to the LedgerSMB instance at startup, or you can provide environment variables to an appropriate Postgres server.

LedgerSMB provides an http interface built on Starman out of the box, listening on port 5762. We do not recommend exposing this port, because we strongly recommend encrypting all connections using SSL/TLS. For production use, we recommend running a web server configured with SSL, such as Nginx or Apache, and proxying connections to LedgerSMB.

The other services you will need to put this in production are an SMTP gateway (set environment variables for SSMTP at container startup) and optionally a local print server (e.g. CUPS) installation. The print service is not currently supported in this Docker image, but pull requests are welcomed ;-)


# How to use this image

## Start a postgres instance

	docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -d postgres

This image includes `EXPOSE 5432` (the postgres port), so standard container linking will make it automatically available to the linked containers. The default `postgres` user and database are created in the entrypoint with `initdb`.

> The postgres database is a default database meant for use by users, utilities and third party applications.  
> [postgresql.org/docs](http://www.postgresql.org/docs/9.3/interactive/app-initdb.html)

## Start LedgerSMB

	docker run --name myledger --link some-postgres:postgres -d ledgersmb/ledgersmb

## Set up LedgerSMB

Visit http://myledger:5762/setup.pl (you can forward port 5762 to the host machine, or lookup the IP address for the "myledger" container if running on localhost)

Log in with the "postgres" user and the password you set when starting up the Postgres container, and provide the name of a company database you want to create.

Once you have completed the setup, you have a fully functional LedgerSMB instance running!

Visit http://myledger:5762/login.pl to log in and get started.

# Updating the LedgerSMB container

No persistant data is stored in the LedgerSMB container. All LedgerSMB data is stored in Postgres, so you can stop/destroy/run a new LedgerSMB container, and as long as you link it to the Postgres database, you should be able to pick up where you left off.

# Environment Variables

The LedgerSMB image uses several environment variables which are easy to miss. While none of the variables are required, they may significantly aid you in using the image.

### `POSTGRES_HOST` = 'postgres'

This environment variable is used to specify the hostname of the Postgres server. The default is "postgres", which will find the container linked in.

If you set this to another hostname, LedgerSMB will attempt to connect to that hostname instead.

### `SSMTP_ROOT` `SSMTP_MAILHUB` `SSMTP_HOSTNAME` `SSMTP_USE_STARTTLS` `SSMTP_AUTH_USER` `SSMTP_AUTH_PASS` `SSMTP_METHOD` `SSMTP_FROMLINE_OVERRIDE`

These variables are used to set outgoing SMTP defaults. To set the outgoing email address, set SSMTP_ROOT, and SSMTP_HOSTNAME at a minimum -- SSMTP_MAILHUB defaults to the default docker0 interface, so if your host is already configured to relay mail, this should relay successfully with only those two set.

Use the other environment variables to relay mail through another host.

# Troubleshooting/Developing

You can connect to a running container using:

> docker exec -ti myledger /bin/bash

... this will give you a shell inside the container where you can inspect/troubleshoot the installation.

Currently the LedgerSMB installation is in /srv/ledgersmb, and the startup/config script is /usr/bin/start.sh.


# Supported Docker versions

This image is officially supported on Docker version 1.11.1.

Support for older versions is provided on a best-effort basis.

# User Feedback

## Documentation

This is a brand new effort, and we will be adding documentation to the http://ledgersmb.org site when we get a chance.

## Issues

If you have any problems with or questions about this image or LedgerSMB, please contact us on the [mailing list](http://ledgersmb.org/topic/support/mailing-lists-rss-and-nntp-feeds) or through a [GitHub issue](https://github.com/ledgersmb/ledgersmb-docker/issues).

You can also reach some of the official LedgerSMB maintainers via the `#ledgersmb` IRC channel on [Freenode](https://freenode.net), or on the bridged [Matrix](https://matrix.org) room in [#ledgersmb:matrix.org](https://matrix.to/#/#ledgersmb:matrix.org). The [Vector.im](https://vector.im/beta/#/room/#ledgersmb:matrix.org) Matrix client is highly recommended.


## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.
