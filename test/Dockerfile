# check=skip=InvalidDefaultArgInFrom
# One image definition for every container gate, parametrised by base image.
# Run it through make, which owns the pinned bases:
#
#   make test-docker        # Ubuntu 24.04: generic Linux, `make` = link only
#   make test-docker-arch   # Arch: `make` = `make arch`, the whole pacmanfile
#
# Omarchy (Arch + Hyprland) is plain Arch for this purpose: same pacman, same
# `make arch` path. There is no separate Omarchy image.
#
# The image carries only what `make` needs before it can run: make, git, sudo
# and a non-root user with passwordless sudo, which is what a fresh machine's
# owner has. Packages, stow, zsh and bats arrive through the repo's own
# targets when the container runs, so the gate proves those targets instead
# of a hand-written package list kept beside them.

# No default on purpose: the pins live in the Makefile beside the target that
# names the distro, and a build without --build-arg BASE should fail rather
# than quietly pick one (hence the check=skip directive on line 1).
ARG BASE
FROM ${BASE}

# pacman's seccomp sandbox cannot start under amd64 emulation on Apple
# Silicon, so it is disabled. apt lists are kept: a real Ubuntu machine has
# them, and `make link`'s stow-linux step relies on them.
RUN if command -v pacman >/dev/null 2>&1; then \
        sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf && \
        pacman -Syu --noconfirm --needed make git sudo && \
        pacman -Scc --noconfirm; \
    else \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            make git sudo ca-certificates; \
    fi && \
    useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser
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

ENV HOME=/home/testuser \
    DOTFILES_DIR=/home/testuser/.dotfiles \
    XDG_CONFIG_HOME=/home/testuser/.config \
    LANG=C.UTF-8

# `make` runs before `make test-setup` on purpose: test-setup installs zsh and
# stow, and running it first would hide a platform target that fails to.
# STRICT_PACKAGES is scoped to that one command: this is a gate, so an
# uninstallable manifest entry must fail it, but the suite asserts the
# tolerant default and must not inherit the override.
CMD ["/bin/bash", "-c", "set -e; cd \"$DOTFILES_DIR\"; STRICT_PACKAGES=1 make; make test-setup; make test; make doctor"]
