FROM --platform=amd64 ubuntu:18.04
RUN set -e \
    && apt-get update \
    && apt-get install --yes python \
    && apt-get install --yes python-pip \
    && pip install --upgrade pip setuptools wheel \
    && pip install obfsproxy \
    && apt-get --yes clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir --parents /opt/obfsproxy
EXPOSE 21194
ENTRYPOINT exec obfsproxy \
    --log-min-severity ${LOG_LEVEL} \
    --data-dir /opt/obfsproxy \
    scramblesuit \
    --password ${PASSWORD} \
    --dest ${DESTINATION_IP} \
    server ${SERVER_IP}