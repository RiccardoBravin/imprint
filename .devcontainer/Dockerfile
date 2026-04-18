# Base Image: Use a stable LTS release
FROM ubuntu:24.04

USER root

ENV LANG=en_US.UTF-8 \
  LC_ALL=en_US.UTF-8 \
  LANGUAGE=en_US:en

# Install essential packages NOT handled by features + Flutter Linux dependencies
# hadolint ignore=DL3008
RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  curl git unzip xz-utils zip libglu1-mesa wget mesa-utils ca-certificates clang cmake ninja-build pkg-config libstdc++-14-dev libgtk-3-dev liblzma-dev locales zenity \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && sh -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' \
  && locale-gen \
  && update-locale LANG=en_US.UTF-8

# --- Manual Flutter SDK Installation ---
# Set Flutter ENV variables
ENV FLUTTER_VERSION="3.44.1"
ENV FLUTTER_HOME=/sdks/flutter
ENV FLUTTER_ROOT=/sdks/flutter
ENV PATH=${PATH}:/sdks/flutter/bin:/sdks/flutter/bin/cache/dart-sdk/bin

# Clone and install Flutter
RUN git clone --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
  && chown -R ubuntu:ubuntu ${FLUTTER_HOME}

USER ubuntu

# Configure flutter first time
RUN flutter config --no-analytics \
  && flutter config --no-enable-android \
  && flutter channel stable \
  && flutter doctor \
  && flutter precache
