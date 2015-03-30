# WebApollo
# VERSION 1.0
FROM tomcat:7
MAINTAINER Eric Rasche <rasche.eric@yandex.ru>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update --fix-missing
RUN apt-get --no-install-recommends -y install git nodejs-legacy build-essential maven2 openjdk-7-jdk libpq-dev postgresql-common postgresql-client xmlstarlet netcat

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm DateTime Text::Markdown DBI DBD::Pg Term::ReadKey Crypt::PBKDF2 JSON Digest::Crc32 Hash::Merge PerlIO::gzip Heap::Simple Bio::GFF3::LowLevel::Parser File::Next && rm -rf /root/.cpanm/
RUN cpanm --force Devel::Size Heap::Simple::XS && rm -rf /root/.cpanm/

RUN mkdir -p /webapollo/ && git clone https://github.com/GMOD/Apollo /webapollo/ && \
    cd /webapollo/ && \
    cp sample_config.properties config.properties && \
    cp sample_config.xml config.xml && \
    cp sample_hibernate.xml hibernate.xml && \
    cp sample_log4j2.json log4j2.json && \
    cp sample_log4j2-test.json log4j2-test.json && \
    ./apollo deploy

ENV DEPLOY_DIR /usr/local/tomcat/webapps/apollo/
ENV APOLLO_ORGANISM "Pythium ultimum"
ENV APOLLO_AUTHENTICATION org.bbop.apollo.web.user.encryptedlocaldb.EncryptedLocalDbUserAuthentication
# If the database is a chado DB, then the hibernate config will be modified
# apporpriately. UNTESTED.
ENV DB_IS_CHADO false

ENV APOLLO_USERNAME web_apollo_admin
ENV APOLLO_PASSWORD password

RUN mkdir -p $DEPLOY_DIR && \
    cp /webapollo/target/apollo-1.0.5-SNAPSHOT.war $DEPLOY_DIR && \
    cd $DEPLOY_DIR && \
    jar xvf apollo-1.0.5-SNAPSHOT.war

ADD startup.sh /bin/
ADD autodetect.sh /bin/
RUN chmod +x /bin/startup.sh /bin/autodetect.sh && mkdir -p /data

VOLUME "/data"
CMD ["/bin/startup.sh"]
