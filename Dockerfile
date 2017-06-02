FROM centos
MAINTAINER doytsujin <doytsujin@noname>

ENV EMBEDDED_RUBY=true PATH=$PATH:/opt/sensu/bin:/opt/sensu/embedded/bin \
    GEM_PATH=/opt/sensu/embedded/lib/ruby/gems/2.2.0:$GEM_PATH

WORKDIR /tmp

RUN curl -L -Ss http://repositories.sensuapp.org/yum/x86_64/sensu-0.26.5-2.el5.x86_64.rpm > /tmp/sensu.rpm \
    && rpm2cpio /tmp/sensu.rpm | cpio -idm && mv /tmp/opt/sensu /opt/ \
    && mv /tmp/etc/sensu /etc/ \
    && rm -rf /tmp/var /tmp/usr /tmp/sensu.rpm /tmp/etc

WORKDIR /

ADD config.json /etc/sensu/
ADD docker-ctl.sh /opt/sensu/bin/
