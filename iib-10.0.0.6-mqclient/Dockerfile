# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM iib:10.0.0.6

MAINTAINER Dennis Seidel <mail@dennisseidel.de>

ENV DEBIAN_FRONTEND=noninteractive

# Install additional packages required by this install process and the runtime scripts
RUN apt-get update \
    && apt-get install -y \
    bash \
    bc \
    rpm \
    tar \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# The URL to download the MQ installer from in tar.gz format
ENV MQ_URL=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev90_linux_x86-64.tar.gz

# The MQ packages to install
ENV MQ_PACKAGES="MQSeriesRuntime-*.rpm MQSeriesClient-*.rpm"

# Download and extract the MQ installation files
RUN mkdir -p /tmp/mq \
    && cd /tmp/mq \
    && curl -LO ${MQ_URL} \
    && tar -zxvf ./*.tar.gz \
    && cd /tmp/mq/MQServer \
    # Accept the MQ license
    && ./mqlicense.sh -text_only -accept \
    # Install MQ using the RPM packages
    && rpm -ivh --force-debian ${MQ_PACKAGES} \
    # Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
    && /opt/mqm/bin/setmqinst -p /opt/mqm -i \
    # Clean up all the downloaded files
    && rm -rf /tmp/mq

# Always use port 1414 (the Docker administrator can re-map ports at runtime)
EXPOSE 1414

