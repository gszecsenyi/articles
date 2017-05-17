# based on input by: Guido Schmutz <@gschmutz>

# parent iamge is the TrivadisBDS Centos image with java installation
FROM            trivadisbds/base

MAINTAINER      Gergely Szecsenyi <gergely.szecsenyi@trivadis.com>

# Define the environment variables for Kafka and Nifi source files, installation homes and versions
ENV             NIFI_DIST_MIRROR             http://mirror.cc.columbia.edu/pub/software/apache/nifi
ENV             NIFI_HOME                    /opt/nifi
ENV             NIFI_VERSION                 1.2.0

ENV             KAFKA_DIST_MIRROR             http://tux.rainside.sk/apache/kafka
ENV             KAFKA_HOME                    /opt/kafka
ENV             KAFKA_VERSION                 0.10.1.0
ENV             SCALA_VERSION                 2.11

# Install necessary packages, create target directory, download and extract, and update the banner to let people know what version they are using
RUN             mkdir -p ${NIFI_HOME} && \
                curl ${NIFI_DIST_MIRROR}/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz | tar xvz -C ${NIFI_HOME} --strip-components=1 && \
                sed -i -e "s|^nifi.ui.banner.text=.*$|nifi.ui.banner.text=Trivadisbds Docker NiFi ${NIFI_VERSION}|" ${NIFI_HOME}/conf/nifi.properties

RUN             wget -c ${KAFKA_DIST_MIRROR}/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                tar -xzvf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt && \
                ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/ ${KAFKA_HOME}

RUN             echo '#!/bin/bash' > /usr/bin/start-kafka.sh && \
                echo "cd ${KAFKA_HOME}" >> /usr/bin/start-kafka.sh && \
                echo "bin/zookeeper-server-start.sh config/zookeeper.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "bin/kafka-server-start.sh config/server.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "${NIFI_HOME}/bin/nifi.sh run & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "tail -f ~/output.log" >> /usr/bin/start-kafka.sh  && \
                chmod +x /usr/bin/start-kafka.sh

# Expose web port
EXPOSE          80 8080 2181 9092

CMD ["start-kafka.sh"]