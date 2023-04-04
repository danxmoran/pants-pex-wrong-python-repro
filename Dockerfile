FROM ubuntu:20.04 AS ubuntu
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 && \
    update-locale en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

FROM ubuntu AS build-base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    dpkg-dev \
    libbz2-dev \
    libffi-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    llvm \
    make \
    tk-dev \
    wget \
    xz-utils \
    zlib1g-dev

ARG PYENV_VERSION=v2.3.13
ARG PYENV_SHA=9105de5e5cf8dc0eca2a520ed04493d183128d46a2cfb402d4cc271af1bf144b
RUN curl -Lo /tmp/pyenv.tar.gz "https://github.com/pyenv/pyenv/archive/refs/tags/${PYENV_VERSION}.tar.gz" \
    && echo "${PYENV_SHA}  /tmp/pyenv.tar.gz" | sha256sum -c \
    && mkdir -p /tmp/pyenv && tar xzf /tmp/pyenv.tar.gz -C /tmp/pyenv --strip-components 1 && rm /tmp/pyenv.tar.gz \
    && /tmp/pyenv/plugins/python-build/install.sh \
    && rm -r /tmp/pyenv

FROM build-base AS build-38

RUN mkdir -p /opt/python/3.8.16 \
    arch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && export arch \
    && MAKE_OPTS="-j $(nproc) LDFLAGS='-Wl,--strip-all'" \
    PYTHON_CONFIGURE_OPTS="--build=${arch} --enable-loadable-sqlite-extensions --enable-option-checking=fatal --enable-shared --with-system-expat --with-system-ffi --without-ensurepip --enable-optimizations" \
    python-build --verbose 3.8.16 /opt/python/3.8.16

RUN find /opt/python/3.8.16 -depth -type f -name '*.a' -exec rm '{}' \;
RUN find /opt/python/3.8.16 -depth -type d -name __pycache__ -exec rm -r '{}' \;
RUN find /opt/python/3.8.16 -depth -type d -a \( -name test -o -name tests -o -name idle_test \) -exec rm -r '{}' \;
RUN find /opt/python/3.8.16 -depth -type f -name '*.exe' -exec rm '{}' \;

FROM build-base AS build-39

RUN mkdir -p /opt/python/3.9.16 \
    arch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
    && export arch \
    && MAKE_OPTS="-j $(nproc) LDFLAGS='-Wl,--strip-all'" \
    PYTHON_CONFIGURE_OPTS="--build=${arch} --enable-loadable-sqlite-extensions --enable-option-checking=fatal --enable-shared --with-system-expat --with-system-ffi --without-ensurepip --enable-optimizations" \
    python-build --verbose 3.9.16 /opt/python/3.9.16

RUN find /opt/python/3.9.16 -depth -type f -name '*.a' -exec rm '{}' \;
RUN find /opt/python/3.9.16 -depth -type d -name __pycache__ -exec rm -r '{}' \;
RUN find /opt/python/3.9.16 -depth -type d -a \( -name test -o -name tests -o -name idle_test \) -exec rm -r '{}' \;
RUN find /opt/python/3.9.16 -depth -type f -name '*.exe' -exec rm '{}' \;

FROM ubuntu AS final

COPY --from=build-38 /opt/python/3.8.16 /opt/python/3.8.16
COPY --from=build-39 /opt/python/3.9.16 /opt/python/3.9.16

ENV PATH="/opt/python/3.9.16/bin:/opt/python/3.8.16/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libexpat1 \
        curl \
        ca-certificates \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV SCIE_PANTS_VERSION=0.5.4
RUN URL="https://github.com/pantsbuild/scie-pants/releases/download/v${SCIE_PANTS_VERSION}/scie-pants-linux-x86_64" \
    && curl -fLo scie-pants "$URL" \
    && install -o root -g root -m 755 scie-pants /usr/local/bin/pants \
    && rm -f scie-pants
