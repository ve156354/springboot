FROM rhel7.2

ENV JAVA_VERSION=8u131 BUILD_VERSION=b11 BUILDER_VERSION=1.0
ENV MAVEN_VERSION 3.3.3
ENV PATH=/opt/maven/bin/:$PATH
ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Spring Boot applications with maven" \
      io.k8s.display-name="Spring Boot builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,maven-3,springboot" \
      io.openshift.s2i.scripts-url=image:///usr/local/sti

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm && \
        yum install -y --setopt=tsflags=nodocs --enablerepo rhel-7-server-optional-rpms --enablerepo rhel-7-server-rpms wget tar unzip bzip2 which && \
                
	( wget http://download.oracle.com/otn/java/jdk/8u45-b14/jdk-8u45-linux-x64.rpm?AuthParam=1497103812_2b8cce304f01aa7bb8781b0f56c23aca -O /tmp/jdk-8-linux-x64.rpm ) && \
        yum -y --setopt=tsflags=nodocs install /tmp/jdk-8-linux-x64.rpm  && \
        yum clean all  && \
        rm  /tmp/jdk-8-linux-x64.rpm && \

        ( curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share) && \
        mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven && \
        ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
        chmod +x /usr/share/maven/conf/settings.xml && \
        mv /usr/share/maven/conf/settings.xml /usr/share/maven/conf/settings1.xml

#Copy maven settings
COPY  settings.xml /usr/share/maven/conf/

#copy the sti scripts
COPY ./.sti/bin/ /usr/local/sti

#Install build tools on top of base image

RUN mkdir -p /opt/openshift && \
    mkdir -p /opt/app-root/source && chmod -R a+rwX /opt/app-root/source && \
    mkdir -p /opt/s2i/destination && chmod -R a+rwX /opt/s2i/destination && \
    mkdir -p /opt/app-root/src && chmod -R a+rwX /opt/app-root/src && \
    chown -R 1001:1001 /opt/openshift && \
    chmod -R a+rwX /usr/local/sti/assemble && \
    chmod -R a+rwX /usr/local/sti/run && \
    chmod -R a+rwX /usr/local/sti/save-artifacts && \
    chmod -R a+rwX /usr/local/sti/usage && \
    chmod +x /usr/local/sti/assemble /usr/local/sti/run /usr/local/sti/save-artifacts /usr/local/sti/usage

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["usage"]
