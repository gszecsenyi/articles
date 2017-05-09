# based on input by: Guido Schmutz <guido.schmutz@trivadis.com>

FROM            trivadisbds/base

MAINTAINER      Gergely Szecsenyi <gergely.szecsenyi@trivadis.com>

ENV             DIST_MIRROR             http://mirror.cc.columbia.edu/pub/software/apache/nifi
ENV             NIFI_HOME               /opt/nifi
ENV             VERSION                 1.2.0

# Install necessary packages, create target directory, download and extract, and update the banner to let people know what version they are using
RUN             mkdir -p /opt/nifi && \
                curl ${DIST_MIRROR}/${VERSION}/nifi-${VERSION}-bin.tar.gz | tar xvz -C ${NIFI_HOME} --strip-components=1 && \
                sed -i -e "s|^nifi.ui.banner.text=.*$|nifi.ui.banner.text=Docker NiFi ${VERSION}|" ${NIFI_HOME}/conf/nifi.properties

RUN wget -c http://tux.rainside.sk/apache/kafka/0.10.1.0/kafka_2.11-0.10.1.0.tgz && tar -xzvf kafka_2.11-0.10.1.0.tgz && mv kafka_2.11-0.10.1.0 /opt && ln -s /opt/kafka_2.11-0.10.1.0/ /opt/kafka

RUN echo '#!/bin/bash' > /usr/bin/start-kafka.sh && echo "cd /opt/kafka" >> /usr/bin/start-kafka.sh && echo "bin/zookeeper-server-start.sh config/zookeeper.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && echo "bin/kafka-server-start.sh config/server.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && echo "${NIFI_HOME}/bin/nifi.sh run & > ~/output.log" >> /usr/bin/start-kafka.sh && echo "tail -f ~/output.log" >> /usr/bin/start-kafka.sh  && chmod +x /usr/bin/start-kafka.sh

# Expose web port 
EXPOSE          80 8080 2181 9082

CMD ["start-kafka.sh"]
