# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

FROM ubuntu:14.04

MAINTAINER Dennis Seidel mail@dennisseidel.de

ENV IIB_VERSION="10.0.0.6"

# Configure system
RUN echo "IIB_${IIB_VERSION}:" > /etc/debian_chroot  && \
    touch /var/log/syslog && \
    chown syslog:adm /var/log/syslog

# Install rsyslog less
RUN apt-get update -y && \
    apt-get install -y \
      rsyslog \
      less \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add IIB Binaries to image and create user
RUN mkdir /opt/ibm && \
    curl http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/integration/${IIB_VERSION}-IIB-LINUX64-DEVELOPER.tar.gz \
    | tar zx --exclude iib-${IIB_VERSION}/tools --directory /opt/ibm && \
    /opt/ibm/iib-${IIB_VERSION}/iib make registry global accept license silently && \
    useradd --create-home --home-dir /home/iibuser -G mqbrkrs iibuser && \
    chgrp -R mqbrkrs /opt/ibm && chmod 770 /opt/ibm # wirklich notwendig? security!

# Create IIB Runtime
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN source /opt/ibm/iib-${IIB_VERSION}/server/bin/mqsiprofile \
&& /opt/ibm/iib-${IIB_VERSION}/server/bin/mqsicreatebroker MYNODE -o advanced \
&& mqsilist -d0 \
&& echo "enable file based authentication" \
&& mqsichangeauthmode MYNODE -s active -m file \
&& mqsistart MYNODE \
&& mqsicreateexecutiongroup MYNODE -e default

# Copy in script files
COPY iib-license-check.sh /usr/local/bin/
COPY iib_env.sh /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

# Set BASH_ENV to source mqsiprofile when using docker exec bash -c
ENV BASH_ENV=/usr/local/bin/iib_env.sh

# Expose default admin port and http port
EXPOSE 4414 7800

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
