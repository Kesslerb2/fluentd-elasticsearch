FROM alpine:latest
ENV DEPS="build-base make" \
  DEPS_RM="build-base make " \
  GEM_NAME="fluent-plugin-elasticsearch fluent-plugin-aws-elasticsearch-service fluent-plugin-prometheus fluent-plugin-detect-exceptions fluent-plugin-concat fluent-plugin-json-in-json-2 fluent-plugin-systemd fluent-plugin-kubernetes_metadata_filter"
# this is required for `apk` commands to run successfully
RUN apk update --no-cache \
  && apk upgrade --no-cache
RUN adduser -H -D -s /sbin/nologin -u 100 fluent -G nogroup
RUN apk add --no-cache ${DEPS} \
    ruby ruby-dev ruby-etc ruby-irb ruby-rdoc ruby-webrick \
  && gem install fluentd ${GEM_NAME} \
  && gem sources --clear-all \
  && gem cleanup \
  && apk del --no-cache ${DEPS_RM} \
    ruby-dev \
  # remove all possible private keys from dependencies/installed software
  && find /usr -type f -name '*.pem' | xargs -I@ sh -c 'if cat @ | grep "PRIVATE KEY" ; then rm -rf @; fi' \
  && rm -rf /usr/bin/gem \
  && rm -rf /sbin/apk \
  # see CVE-2017-16516 for the immediate below
  && rm -rf /usr/lib/ruby/gems/*/gems/yajl-ruby-*/spec
# copy a default configuration in and tell fluentd to use that
COPY --chown=fluent:nogroup ./config/fluent/default.conf /fluentd/etc/fluent.conf
# create directory with correct permissions for fluentd
RUN mkdir -p /fluentd/etc \
  && chown fluent:nogroup -R /fluentd \
  && chmod 440 /fluentd/etc/fluent.conf
# we use the output of this script for populating the tags
COPY --chown=fluent:nogroup ./scripts/version-info /usr/bin
ENV FLUENT_CONF=/fluentd/etc/fluent.conf
# switching back to fluent here before anyone nags
USER fluent
# other non-impact documentation stuff
WORKDIR /
EXPOSE 24224 24231
VOLUME [ "/fluentd/etc" ]
ENTRYPOINT [ "fluentd" ]
LABEL maintainer "Brian Kessler"
LABEL description "An extension of govtechsg's production hardened image containing fluentd for use with an elasticsearch service and more plugins"
LABEL source_url "https://github.com/Kesslerb2/fluentd-elasticsearch"
LABEL dockerhub_url "https://hub.docker.com/r/kesslerb2/fluentd-elasticsearch"
LABEL usage "docker run -it kesslerb2/fluentd-elasticsearch:latest"
