FROM php:8.1-cli

LABEL org.opencontainers.image.authors="Alex Skrypnyk <alex@drevops.com>" maintainer="Alex Skrypnyk <alex@drevops.com>"

# Ensure temporary files are not retained in the image.
VOLUME /tmp

# hadolint ignore=DL3008
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends git openssh-client lsof zip unzip vim lynx curl aspell-en jq tree rsync \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install shellcheck
# @see https://github.com/koalaman/shellcheck/releases
ENV SHELLCHECK_VERSION=0.9.0
RUN curl -L -o "/tmp/shellcheck-v${SHELLCHECK_VERSION}.tar.xz" "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
  && tar --xz -xvf "/tmp/shellcheck-v${SHELLCHECK_VERSION}.tar.xz" \
  && mv "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /usr/bin/ \
  && shellcheck --version

# Install Docker and Docker Compose V2 (docker compose).
# @see https://download.docker.com/linux/static/stable/x86_64
# @see https://github.com/docker/compose/releases
ENV DOCKER_VERSION=24.0.5
ENV DOCKER_COMPOSE_VERSION=v2.20.2
RUN curl -L -o "/tmp/docker-${DOCKER_VERSION}.tgz" "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    && tar -xz -C /tmp -f "/tmp/docker-${DOCKER_VERSION}.tgz" \
    && mv /tmp/docker/* /usr/bin \
    && docker --version \
    && mkdir -p "$HOME/.docker/cli-plugins" \
    && curl -sSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "$HOME/.docker/cli-plugins/docker-compose" \
    && chmod +x "$HOME/.docker/cli-plugins/docker-compose" \
    && docker compose version

# Install Docker Compose V1 (docker-compose).
ENV DOCKER_COMPOSE_LEGACY_VERSION=1.29.2
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_LEGACY_VERSION}/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && docker-compose version \
    && echo "WARNING: Docker Compose v1 will be deprecated as of July 2023 and will not be included in future versions of this image. We strongly encourage users to transition to Docker Compose v2 for continued support and improved functionality." >&2

# Install Docker buildx (docker buildx).
# @see https://github.com/docker/buildx/releases
ENV BUILDX_VERSION=v0.11.2
RUN mkdir -vp ~/.docker/cli-plugins \
    && curl --silent -L "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" > ~/.docker/cli-plugins/docker-buildx \
    && chmod a+x ~/.docker/cli-plugins/docker-buildx \
    && docker buildx version

# Install composer.
# @see https://getcomposer.org/download
ENV COMPOSER_VERSION=2.5.8
ENV COMPOSER_SHA=e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02
ENV COMPOSER_ALLOW_SUPERUSER=1
# hadolint ignore=DL4006
RUN curl -L -o "/usr/local/bin/composer" "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
    && echo "${COMPOSER_SHA} /usr/local/bin/composer" | sha256sum \
    && chmod +x /usr/local/bin/composer \
    && composer --version \
    && composer clear-cache
ENV PATH /root/.composer/vendor/bin:$PATH

# Install NVM and NodeJS.
# @see https://github.com/nvm-sh/nvm/releases
ENV NVM_VERSION=v0.39.4
ENV NVM_DIR=/root/.nvm
# hadolint ignore=DL4006,SC1091
RUN mkdir -p "${NVM_DIR}" \
  && curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash \
  && . "$HOME/.nvm/nvm.sh" \
  && nvm --version

ENV SHIPPABLE_NODE_VERSION=v20.5.0
# hadolint ignore=SC1091
RUN . "$HOME/.nvm/nvm.sh" \
	&& nvm install "${SHIPPABLE_NODE_VERSION}" \
	&& nvm alias default "${SHIPPABLE_NODE_VERSION}" \
	&& nvm use default \
	&& npm --version
ENV PATH ${NVM_DIR}/versions/node/${SHIPPABLE_NODE_VERSION}/bin:$PATH

# Install Goss.
# @see https://github.com/aelsabbahy/goss
ENV GOSS_VER=v0.3.23
ENV GOSS_FILES_STRATEGY=cp
# hadolint ignore=DL4006
RUN curl -fsSL https://goss.rocks/install | sh \
  && goss --version

# Install Bats.
# @see https://github.com/bats-core/bats-core/releases
ENV BATS_VERSION=v1.10.0
# hadolint ignore=DL3003
RUN curl -L -o "/tmp/bats.tar.gz" "https://github.com/bats-core/bats-core/archive/${BATS_VERSION}.tar.gz" \
    && mkdir -p /tmp/bats && tar -xz -C /tmp/bats -f /tmp/bats.tar.gz --strip 1 \
    && cd /tmp/bats \
    && ./install.sh /usr/local \
    && bats -v

# Install Ahoy.
# @see https://github.com/ahoy-cli/ahoy/releases
ENV AHOY_VERSION=v2.1.1
RUN curl -L -o "/usr/local/bin/ahoy" "https://github.com/ahoy-cli/ahoy/releases/download/${AHOY_VERSION}/ahoy-bin-$(uname -s)-amd64" \
  && chmod +x /usr/local/bin/ahoy \
  && ahoy --version

# Install a stub for pygmy.
# Some frameworks may require presence of pygmy to run, but pygmy is not required in CI container.
RUN touch /usr/local/bin/pygmy \
 && chmod +x /usr/local/bin/pygmy

# Create a stub for sendmail.
RUN ln -s /usr/bin/true /usr/local/bin/sendmail
