# This software is Copyright (c) 2014 by Chris Weyl <chris.weyl@wps.io>
#
# This work is licensed under a Creative Commons Attribution-ShareAlike 4.0
# International License (CC-BY-SA-4.0).
#
# http://creativecommons.org/licenses/by-sa/4.0/

FROM ubuntu:precise
MAINTAINER Chris Weyl <chris.weyl@wps.io>

# update packages
ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24
RUN echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu precise main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y install git openssh-server
RUN mkdir -p /var/run/sshd

# fetch the gitolite source (latest upstream by default)...
RUN umask 0022
RUN mkdir -p /usr/local/src
RUN git clone git://github.com/sitaramc/gitolite /usr/local/src/gitolite
WORKDIR /usr/local/src/gitolite 
RUN git checkout v3.6.2
WORKDIR /

# install gitolite...
RUN /usr/local/src/gitolite/install -to /usr/local/bin

# install our run script
RUN mkdir -p /usr/local/sbin
ADD gitolite-run /usr/local/sbin/gitolite-run
RUN chown root.root /usr/local/sbin/gitolite-run && chmod 0755 /usr/local/sbin/gitolite-run

# ...and our admin public key
ADD admin.pub /usr/local/src/admin.pub
RUN chown root.root /usr/local/src/admin.pub && chmod 0644 /usr/local/src/admin.pub

# add our gitolite system user
RUN useradd --home /srv/git --system --comment 'gitolite system user' git

# our externally bits.
VOLUME ["/srv"]
EXPOSE 22
ENTRYPOINT ["/usr/local/sbin/gitolite-run"]

# --------------
#
# These will be run as part of the initial build of any *children* containers.
# This should allow us to be able to easily create containers with specific
# ssh keypairs.

# builds FROM this one will do the full install to the /srv volume -- this is
# handled in gitolite-run, however.

ONBUILD ADD admin.pub /usr/local/src/admin.pub
ONBUILD RUN chown root.root /usr/local/src/admin.pub && chmod 0644 /usr/local/src/admin.pub
