FROM ubuntu:18.04

MAINTAINER Yuki Watanabe <watanabe@future-needs.com>

ARG USER_ID
ARG GROUP_ID

ENV HOME /bitcoincash

# add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} bitcoincash \
	&& useradd -u ${USER_ID} -g bitcoincash -s /bin/bash -m -d /bitcoincash bitcoincash

ARG BITCOINCASH_VERSION=${BITCOINCASH_VERSION:-0.21.1}
ENV BITCOIN_PREFIX=/opt/bitcoincash-${BITCOINCASH_VERSION}
ENV BITCOIN_DATA=/bitcoincash/.bitcoincash
ENV PATH=/bitcoincash/bitcoin-abc-${BITCOINCASH_VERSION}/bin:$PATH

RUN set -xe \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
        ca-certificates \
        gnupg \
        unzip \
        curl \
        && curl -SLO https://github.com/Bitcoin-ABC/bitcoin-abc/releases/download/v${BITCOINCASH_VERSION}/bitcoin-abc-${BITCOINCASH_VERSION}-x86_64-linux-gnu.tar.gz \
        && tar -xzf *.tar.gz -C /bitcoincash \
        && rm *.tar.gz \
        && apt-get purge -y \
        ca-certificates \
        curl \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# grab gosu for easy step-down from root
ARG GOSU_VERSION=${GOSU_VERSION:-1.11}
RUN set -xe \
	&& apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y \
		ca-certificates \
		wget \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ./bin /usr/local/bin

VOLUME ["/bitcoincash"]

EXPOSE 8332 8333 18332 18333

WORKDIR /bitcoincash

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["bch_oneshot"]
