# WebApollo
# VERSION 1.0
FROM tomcat:7
MAINTAINER Eric Rasche <rasche.eric@yandex.ru>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update
RUN apt-get --no-install-recommends -y install git nodejs-legacy build-essential maven2 openjdk-7-jdk

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm DateTime Text::Markdown

RUN mkdir -p /webapollo/ && git clone https://github.com/GMOD/Apollo /webapollo/ && \
    cd /webapollo/ && \
    cp sample_config.properties config.properties && \
    cp sample_config.xml config.xml && \
    cp sample_log4j2.json log4j2.json && \
    cp sample_log4j2-test.json log4j2-test.json && \
    ./apollo deploy

RUN cp /webapollo/target/apollo-1.0.5-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT/ && \
    cd /usr/local/tomcat/webapps/ROOT/ && \
    jar xvf /usr/local/tomcat/webapps/ROOT/apollo-1.0.5-SNAPSHOT.war
