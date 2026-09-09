# Dockerfile for testing dotfiles installation
#
# Build: docker build -t dotfiles-test -f test/Dockerfile .
# Run:   docker run --rm dotfiles-test
#
# This tests the dotfiles installation in a clean Ubuntu environment.

FROM ubuntu:22.04@sha256:3ba65aa20f86a0fad9df2b2c259c613df006b2e6d0bfcc8a146afb8c525a9751

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    stow \
    zsh \
    sudo \
    make \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu's `bats` package is 1.2.1, which predates
# bats_require_minimum_version and `run --separate-stderr`. Installing it
# made test_shell_boot.bats die with status 127 and silently cost the run
# two tests. Install bats-core from source instead.
ARG BATS_VERSION=1.11.0
RUN git clone --depth 1 --branch "v${BATS_VERSION}" \
        https://github.com/bats-core/bats-core.git /tmp/bats-core \
    && /tmp/bats-core/install.sh /usr/local \
    && rm -rf /tmp/bats-core

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user for testing
RUN useradd -m -s /bin/zsh testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Copy dotfiles repository
COPY --chown=testuser:testuser . /home/testuser/.dotfiles

# Set environment variables
ENV HOME=/home/testuser
ENV DOTFILES_DIR=/home/testuser/.dotfiles
ENV XDG_CONFIG_HOME=/home/testuser/.config

# Default command: run tests and link
CMD ["/bin/bash", "-c", "cd $DOTFILES_DIR && make test && make link && make doctor"]
