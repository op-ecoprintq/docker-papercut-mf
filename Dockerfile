# Use Ubuntu 19.04 base image
FROM ubuntu:19.04
LABEL maintainer="ecoprintQ"
LABEL description="PaperCut MF Application Server"

# Variables
ENV PAPERCUT_VERSION 19.0.3.49324
ENV PAPERCUT_DOWNLOAD_URL https://cdn1.papercut.com/web/products/ng-mf/installers/mf/19.x/pcmf-setup-${PAPERCUT_VERSION}.sh

# Set to non-interactive mode for the build
ARG DEBIAN_FRONTEND=noninteractive

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

# Switch user and directory
USER papercut
WORKDIR /home/papercut

# Download papercut
RUN wget ${PAPERCUT_DOWNLOAD_URL} -nv

# Run the PaperCut installer
RUN sh ./pcmf-setup-${PAPERCUT_VERSION}.sh -e
RUN rm /home/papercut/papercut/LICENCE.TXT
RUN sed -i 's/read reply leftover//g' papercut/install
RUN sed -i 's/answered=/answered=0/g' papercut/install
RUN papercut/install

# Switch back to root user and run the root commands
USER root
RUN /home/papercut/server/bin/linux-x64/roottasks

# Volumes
VOLUME /home/papercut/server/logs /papercut/server/data /home/papercut/server/custom /home/papercut/server/server.properties

# Ports
EXPOSE 9191 9192 9193

ENTRYPOINT ["/entrypoint.sh"]
