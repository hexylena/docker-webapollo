# WebApollo
# VERSION 0.1
FROM java:7-jre
MAINTAINER Eric Rasche <rasche.eric@yandex.ru>
ENV DEBIAN_FRONTEND noninteractive

# Taken from https://github.com/docker-library/official-images/commit/6d78950ab2b59e211f3ec9735fb7ec0da239adf9
RUN groupadd -r tomcat && useradd -r --create-home -g tomcat tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH /usr/local/tomcat/bin:$PATH
RUN mkdir -p /usr/local/tomcat/ && chown tomcat:tomcat /usr/local/tomcat/
RUN gpg --keyserver pgp.mit.edu --recv-keys \
    05AB33110949707C93A279E3D3EFE6B686867BA6 \
    07E48665A34DCAFAE522E5E6266191C37C037D42 \
    47309207D818FFD8DCD3F83F1931D684307A10A5 \
    541FBE7D8F78B25E055DDEE13C370389288584E7 \
    61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
    713DA88BE50911535FE716F5208B0AB1D63011C7 \
    79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
    9BA44C2621385CB966EBA586F72C284D731FABEE \
    A27677289986DB50844682F8ACB77FC2E86E29AC \
    A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
    DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
    F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
    F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV TOMCAT_MAJOR 7
ENV TOMCAT_VERSION 7.0.56
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

WORKDIR /usr/local/tomcat/
RUN curl -SL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
    && curl -SL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
    && gpg --verify tomcat.tar.gz.asc \
    && tar -xvf tomcat.tar.gz --strip-components=1 \
    && rm bin/*.bat \
    && rm tomcat.tar.gz*

RUN apt-get -qq update
RUN apt-get --no-install-recommends -y install postgresql postgresql-client \
    libpng-dev zlib1g zlib1g-dev build-essential make libpq-dev libperlio-gzip-perl \
    libcapture-tiny-perl libtest-differences-perl libperlio-gzip-perl \
    libdevel-size-perl libdbi-perl libjson-perl libjson-xs-perl libheap-perl \
    libhash-merge-perl libdbd-pg-perl libio-string-perl libtest-most-perl \
    libarray-compare-perl libconvert-binary-c-perl libgd-perl libgraph-perl \
    libgraphviz-perl libsoap-lite-perl libsvg-perl libsvg-graph-perl \
    libset-scalar-perl libsort-naturally-perl libxml-sax-perl libxml-twig-perl \
    libxml-writer-perl libyaml-perl sudo openjdk-7-jre openjdk-7-jdk

RUN curl -L http://cpanmin.us | perl - App::cpanminus
# Some have to be forced.
RUN cpanm --force Test::More Heap::Simple Heap::Simple::XS
# But most install just fine
RUN cpanm DBI Digest::Crc32 Cache::Ref::FIFO URI::Escape HTML::Entities \
    HTML::HeadParser HTML::TableExtract HTTP::Request::Common LWP XML::Parser \
    XML::Parser::PerlSAX XML::SAX::Writer XML::Simple Data::Stag \
    Error PostScript::TextBlock Spreadsheet::ParseExcel Algorithm::Munkres \
    BioPerl Bio::GFF3::LowLevel::Parser File::Next

ENV CATALINA_OPTS -Xms512m -Xmx1g -XX:+CMSClassUnloadingEnabled -XX:+CMSPermGenSweepingEnabled -XX:+UseConcMarkSweepGC -XX:MaxPermSize=256m
ENV WEB_APOLLO_DIR /usr/local/webapollo/
ENV WEB_APOLLO_SAMPLE_DIR /usr/local/webapollo/webapollo_sample
ENV WEB_APOLLO_DATA_DIR /data/webapollo/annotations
ENV JBROWSE_DATA_DIR /data/webapollo/jbrowse/data
ENV TOMCAT_LIB_DIR /usr/local/tomcat/lib
ENV TOMCAT_CONF_DIR /usr/local/tomcat/conf
ENV TOMCAT_WEBAPPS_DIR /usr/local/tomcat/webapps
ENV BLAT_DIR /usr/local/bin
ENV BLAT_TMP_DIR /data/webapollo/blat/tmp
ENV BLAT_DATABASE /data/webapollo/blat/db/pyu.2bit

RUN mkdir -p /usr/local/webapollo/ && mkdir -p /data/webapollo/jbrowse/data

# WebApollo Installation
RUN wget http://icebox.lbl.gov/webapollo/releases/WebApollo-2014-04-03.tgz -O /tmp/webapollo.tgz \
    && cd /usr/local/webapollo && tar xvfz /tmp/webapollo.tgz \
    && mv WebApollo*/* . && rmdir WebApollo* && rm /tmp/webapollo.tgz
RUN cd /usr/local/webapollo/ && wget http://icebox.lbl.gov/webapollo/data/pyu_data.tgz && tar xvfz pyu_data.tgz && rm pyu_data.tgz \
    && mkdir -p /usr/local/webapollo/webapollo_sample && mv pyu_data/* /usr/local/webapollo/webapollo_sample/

RUN cp /usr/local/webapollo/tomcat/custom-valves.jar /usr/local/tomcat/lib && cd /usr/local/tomcat/webapps && mkdir WebApollo && cd WebApollo && jar -xvf /usr/local/webapollo/war/WebApollo.war

COPY ./pg_hba.conf /etc/postgresql/9.4/main/pg_hba.conf
COPY ./config.xml /usr/local/tomcat/webapps/WebApollo/config/config.xml

# Build default Pythium data, for some reason bigwig data isn't working yet.
RUN cd /usr/local/tomcat/webapps/WebApollo/jbrowse/ && chmod 755 bin/* && ln -sf /data/webapollo/jbrowse/data data && bin/prepare-refseqs.pl --fasta /usr/local/webapollo/webapollo_sample/scf1117875582023.fa \
    && bin/add-webapollo-plugin.pl -i data/trackList.json && mkdir -p /usr/local/webapollo/webapollo_sample/split_gff \
    && /usr/local/webapollo/tools/data/split_gff_by_source.pl -i /usr/local/webapollo/webapollo_sample/scf1117875582023.gff -d /usr/local/webapollo/webapollo_sample/split_gff \
    &&  bin/flatfile-to-json.pl --gff /usr/local/webapollo/webapollo_sample/split_gff/maker.gff --arrowheadClass trellis-arrowhead --getSubfeatures \
    --subfeatureClasses '{"wholeCDS": null, "CDS":"brightgreen-80pct", "UTR": "darkgreen-60pct", "exon":"container-100pct"}' --className container-16px --type mRNA --trackLabel maker \
    && bin/flatfile-to-json.pl --gff /usr/local/webapollo/webapollo_sample/split_gff/maker.gff --getSubfeatures --type mRNA --trackLabel maker \
    && bin/flatfile-to-json.pl --gff /usr/local/webapollo/webapollo_sample/split_gff/blastn.gff \
    --arrowheadClass webapollo-arrowhead --getSubfeatures \
    --subfeatureClasses '{"match_part": "darkblue-80pct"}' \
    --className container-10px --trackLabel blastn \
    && mkdir data/bam && cp /usr/local/webapollo/webapollo_sample/*.bam* data/bam \

COPY ./startup.sh /startup.sh
RUN chmod +x /startup.sh
CMD ["/startup.sh"]
EXPOSE 8080
