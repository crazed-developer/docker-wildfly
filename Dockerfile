# Inspired / taken from:
# https://github.com/jboss-dockerfiles/wildfly

# Build with this command:
# docker build -t cecotto/wildfly:25-jdk16-b02 .
# docker build -t cecotto/wildfly:25-jdk17-b01 .

# Push image
# docker push cecotto/wildfly:26-jdk17-b01

# Run container into bash
# docker run -p 8080:8080 --name test -it [ImageID]

# Login to container:
# docker exec -ti -u root [ContainerID] /bin/bash
FROM eclipse-temurin:17.0.1_12-jdk-focal

run apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias en_DK.UTF-8

ENV LANG en_DK.utf8

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss

USER jboss

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 26.0.0.Final
ENV WILDFLY_SHA1 836fdefc48b6008904b91b43e00bf6ee6d917486
ENV JBOSS_HOME /opt/jboss/wildfly

USER root

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -L -O https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Expose the ports in which we're interested
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in standalone mode and bind to all interfaces
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]