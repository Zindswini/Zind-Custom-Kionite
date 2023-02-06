ARG FEDORA_MAJOR_VERSION=37

FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_MAJOR_VERSION}
# See https://pagure.io/releng/issue/11047 for final location

# Clear out the repos we don't want
RUN rm -rf /etc/yum.repos.d


# VERY IMPORTANT: This is where a lot of customizations happen
COPY root/ /
COPY ublue-firstboot /usr/bin

# Install RPMFusion
RUN set -x; arch=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'); cat /etc/os-release \
    && rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
    && ostree container commit

# Initial round of customizations: # removed mozilla-openh264
RUN rpm-ostree override remove firefox firefox-langpacks && \
    rpm-ostree install just dash vim && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable flatpak-automatic.timer && \
    ostree container commit

# Install "debugging" tools
# These are packages which are useful for managing the system or required to enhance the desktop experience.
# I am trying to keep this as minimal as possible to encourage use of essentially everything inside of distroboxes.
# These are broken into sections, generally based onto category/update frequency

# are all of these really necessary?
RUN set -x; PACKAGES_INSTALL="bridge-utils conntrack-tools iputils iproute mtr nethogs socat"; \
    rpm-ostree install $PACKAGES_INSTALL && ostree container commit

RUN set -x; PACKAGES_INSTALL="net-tools bind-utils iputils mtr ethtool tftp wget ipmitool"; \
    rpm-ostree install $PACKAGES_INSTALL && ostree container commit

RUN set -x; PACKAGES_INSTALL="gawk htop btop iftop ncdu procps strace iotop"; \
    rpm-ostree install $PACKAGES_INSTALL && ostree container commit

RUN set -x; PACKAGES_INSTALL="gnupg2 openssl openvpn rsync tcpdump"; \
    rpm-ostree install $PACKAGES_INSTALL && ostree container commit

RUN set -x; PACKAGES_INSTALL="qemu-kvm qemu-user-static libvirt"; \
    rpm-ostree install $PACKAGES_INSTALL && ostree container commit


# Change boot shell to dash
RUN rm -f /bin/sh && ln -s /usr/bin/dash /bin/sh

# TODO: Check if cleanup is needed
RUN rpm-ostree cleanup -m && \
    ostree container commit
