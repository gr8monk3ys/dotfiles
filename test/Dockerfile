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
    bats \
    locales \
    && rm -rf /var/lib/apt/lists/*

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
