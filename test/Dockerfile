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

# Several tests ask git about the checkout (`git grep` for leaked identity,
# `git check-ignore` for untracked SSH hosts). In a git *worktree* — which
# bin/dotfiles-worktree hands out — `.git` is a pointer file naming a gitdir
# that does not exist inside the image, so every git command exits 128 and
# those tests fail for a reason that has nothing to do with the dotfiles.
# Replace the pointer with a real one-commit repo of the same tree.
RUN if [ ! -d /home/testuser/.dotfiles/.git ]; then \
        rm -f /home/testuser/.dotfiles/.git && \
        git -C /home/testuser/.dotfiles init -q && \
        git -C /home/testuser/.dotfiles add -A && \
        git -C /home/testuser/.dotfiles \
            -c user.email=test@example.invalid -c user.name=Container \
            commit -qm "container snapshot"; \
    fi

# Set environment variables
ENV HOME=/home/testuser
ENV DOTFILES_DIR=/home/testuser/.dotfiles
ENV XDG_CONFIG_HOME=/home/testuser/.config

# Default command: run tests and link
CMD ["/bin/bash", "-c", "cd $DOTFILES_DIR && make test && make link && make doctor"]
