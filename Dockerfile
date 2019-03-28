# Use Ubuntu 18.04 LTS base image
FROM ubuntu:18.04
LABEL maintainer="ecoprintQ"
LABEL description="PaperCut MF Application Server"

# Variables
ENV PAPERCUT_VERSION 18.3.8.48906
ENV PAPERCUT_DOWNLOAD_URL https://cdn1.papercut.com/web/products/ng-mf/installers/mf/18.x/pcmf-setup-${PAPERCUT_VERSION}.sh

# Update Ubuntu
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install wget cpio -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# entrypoint.sh is a script to initialize the db if necessary
COPY entrypoint.sh /

# Make entrypoint.sh executable
RUN chmod +x /entrypoint.sh

# Create papercut user and home
RUN useradd -m -d /home/papercut papercut
RUN usermod -s /bin/bash papercut
ENV PAPERCUT_HOME /home/papercut

# Switch user and directory
USER papercut
WORKDIR /home/papercut

# Download papercut
RUN wget "${PAPERCUT_DOWNLOAD_URL}" -O pcmf-setup.sh

# Run the PaperCut installer
RUN sh ./pcmf-setup.sh --non-interactive
RUN rm -f pcmf-setup.sh


# Switch back to root user and run the root commands
USER root
RUN ${PAPERCUT_HOME}/MUST-RUN-AS-ROOT

# Stopping Papercut services before capturing image
RUN /etc/init.d/papercut stop
RUN /etc/init.d/papercut-web-print stop

# Volumes
VOLUME /home/papercut/server/logs /home/papercut/server/data

# Ports
EXPOSE 9191 9192 9193

ENTRYPOINT ["/entrypoint.sh"]
