FROM node:slim

ARG app_version

COPY etc/bash_completion.d/* /etc/bash_completion.d/
COPY root/ /root/
# Disable prompts from apt.
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    jq && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apt/archives/* /var/lib/apt/lists/*

RUN npm install --global xo-cli@${app_version}

COPY "entrypoint.sh" "/entrypoint.sh"
RUN chmod +x "/entrypoint.sh"
ENTRYPOINT ["/entrypoint.sh"]
