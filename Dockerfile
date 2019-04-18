# Use Ubuntu 18.04 LTS base image
FROM ubuntu:18.04
LABEL maintainer="ecoprintQ"
LABEL description="PaperCut MF Application Server"

# Variables
ENV PAPERCUT_VERSION 19.0.2.49181
ENV PAPERCUT_DOWNLOAD_URL https://cdn1.papercut.com/web/products/ng-mf/installers/mf/18.x/pcmf-setup-${PAPERCUT_VERSION}.sh

# Update Ubuntu
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# entrypoint.sh is a script to initialize the db if necessary
COPY entrypoint.sh /

# Make entrypoint.sh executable
RUN chmod +x /entrypoint.sh

# Create papercut user and home
RUN useradd -m -d /home/papercut papercut
ENV PAPERCUT_HOME /home/papercut

# Switch user and directory
USER papercut
WORKDIR /home/papercut

# Download papercut
RUN wget "#{PAPERCUT_DOWNLOAD_URL}"

# Run the PaperCut installer
RUN sh ./pcmf-setup-${PAPERCUT_VERSION}.sh -e
RUN rm /home/papercut/papercut/LICENCE.TXT
RUN sed -i 's/read reply leftover//g' papercut/install
RUN sed -i 's/answered=/answered=0/g' papercut/install
RUN papercut/install

# Switch back to root user and run the root commands
USER root
RUN ${HOME}/server/bin/linux-x64/roottasks

# Stop web print and print provider services
RUN systemctl stop pc-web-print.service
RUN systemctl stop pc-event-monitor.service

# Volumes
VOLUME /home/papercut/server/logs /papercut/server/data

# Ports
EXPOSE 9191 9192 9193

ENTRYPOINT ["/entrypoint.sh"]
