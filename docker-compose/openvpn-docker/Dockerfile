FROM --platform=amd64 ubuntu:18.04
RUN set -e \
    && apt-get update \
    && apt-get --yes install ca-certificates wget net-tools gnupg \
    && wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg | apt-key add - \
    && echo "deb http://as-repository.openvpn.net/as/debian bionic main" > /etc/apt/sources.list.d/openvpn-as-repo.list \
    && apt-get update \
    && apt-get --yes install openvpn-as \
    && apt-get --yes clean \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/local/openvpn_as/scripts
COPY entrypoint.sh .
EXPOSE 443 943
ENTRYPOINT ./entrypoint.sh \
    --admin-password ${ADMIN_PASSWORD} \
    --user-name ${USER_NAME} \
    --user-password ${USER_PASSWORD}