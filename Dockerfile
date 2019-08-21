# Use Ubuntu 19.04 base image
FROM ubuntu:19.04
LABEL maintainer="ecoprintQ"
LABEL description="PaperCut MF Application Server"

# Variables
ENV PAPERCUT_VERSION 19.1.1.51949
ENV PAPERCUT_DOWNLOAD_URL https://cdn1.papercut.com/web/products/ng-mf/installers/mf/19.x/pcmf-setup-${PAPERCUT_VERSION}.sh

# Set to non-interactive mode for the build
ARG DEBIAN_FRONTEND=noninteractive

# Update Ubuntu
RUN apt-get update \
    && apt-get install wget cpio -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# entrypoint.sh is a script to initialize the db if necessary
COPY entrypoint.sh /

# Create papercut user and home
RUN chmod +x /entrypoint.sh \
    && useradd -m -d /home/papercut papercut

# Switch user and directory
USER papercut
WORKDIR /home/papercut

# Run the PaperCut installer & cleanup
RUN wget ${PAPERCUT_DOWNLOAD_URL} -nv \
    && sh /home/papercut/pcmf-setup-${PAPERCUT_VERSION}.sh -e \
    && sh /home/papercut/papercut/install --non-interactive --no-version-check \
    && sh /home/papercut/server/bin/linux-x64/create-ssl-keystore -f -keystoreentry highsec -sig sha256 -bcCa \
    && rm -rf /home/papercut/papercut/

# Switch back to root user and run the root commands
USER root
RUN /home/papercut/server/bin/linux-x64/roottasks

# Volumes
VOLUME /home/papercut/server/logs /home/papercut/server/data

# Ports
EXPOSE 9191 9192 9193

ENTRYPOINT ["/entrypoint.sh"]
