# Streaming Twitter to Kafka with Apache Nifi

A very common BigData use-case is the collection and processing of Twitter tweets. It can be done on different ways. The Twitter stream can be stored on HDFS or another local drive or immediately processed with a streaming supported engine as Storm, Spark or Flink. In both cases the first step is that the tweets will be collected in a Kafka queue.

Kafka is a horizontally scalable, fault-tolerant distributed publish-subscribe messaging platform. It is written in Scala and was originally developed by LinkedIn. Suitable for both offline and online message consumption. 

Twitter delivers API, what should be accessed. Some years ago this was a bit complex part of the solutions, now, with the help of Apache Nifi it is getting simpler. The only task that has to be done is, to setup a Kafka (with zookeeper) and a Nifi in a docker container or on a server.

This article is about the setup of the environment and the configuration of the Kafka producer with Apache Nifi.

## Start using the environment

### Preparations

#### Register a twitter account and create application for authentication informations

The first step to do is to register a Twitter account on http://twitter.com, and an application on http://apps.twitter.com URL.

After the registration an application key has to be created on the same site. 

This information are needed from Twitter:

* Consumer Key
* Consumer Secret 
* Access Token
* Access Token Secret

### Create and execute the container 

Now the container can be created. If the docker image is not available on the local host, the docker client will download it automatically.The size of the image is about 1GB.


```
docker run -i -d --name twitter2kafka_container -p 8080:8080 -p 2181:2181 -p 9092:9092 -t gszecsenyi/twitter2kafka 
```

There are three port assignments. 

The first is the port of the Apache Nifi client. It can be accessed by Apache Nifi or via Internet Browser. 
The second and the third ports are for zookeeper and  for Kafka. With the third port the Kafka queue can be accessed.

### Create Kafka topic

Open a new shell and execute the following command to login into the running container:

```
docker exec -it twitter2kafka_container /bin/bash
```
After this step a Twitter topic can be created within Kafka:
```
/opt/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic twitter
```

![alt text](https://cloud.githubusercontent.com/assets/363452/26026236/1fac5eda-37f8-11e7-99dd-4dbd8877c65d.png "Create Kafka topic")

### Start using Nifi

1-2 Minutes after the execution of the container, the Nifi can be opened and used in a browser on the http://localhost:8080/nifi address.


![alt text](https://cloud.githubusercontent.com/assets/363452/26026243/200e02fc-37f8-11e7-81ad-d55da300a69f.png "Start using Nifi")

At this point two processor has to be added:

* GetTwitter
* PublishKafka_0_10

They can be joined from GetTwitter to PublishKafka_0_10 Processor.

![alt text](https://cloud.githubusercontent.com/assets/363452/26026240/1fedc12c-37f8-11e7-9894-b3eac4434419.png "Start using Nifi")

### Setup GetTwitter
The configuration window can be accessed by right mouse click on GetTwitter. The following attributes has to be filled:

* Consumer Key
* Consumer Secret Key
* AK
* AKS

![alt text](https://cloud.githubusercontent.com/assets/363452/26026238/1fcd4b68-37f8-11e7-9a63-25fbbf00f358.png "Setup GetTwitter")


Click on Apply.

### Setup PublishKafka_0_10
Open the configuration window from PublishKafka by right click on PulishKafka_0_10. Fill the attribute:

* topic

Here fill out with the Kafka topic, which is _twitter_ 

![alt text](https://cloud.githubusercontent.com/assets/363452/26026237/1fcc1b94-37f8-11e7-813e-ab93a1c26905.png "Setup PublishKafka_0_10")

After clicking the ‘Apply’ button the task is done.

### Executing the dataflow

The Process group can be executed with the play button on the Dashboard.

![alt text](https://cloud.githubusercontent.com/assets/363452/26026235/1f89b146-37f8-11e7-96e8-a9be8dcd452a.png "Executing the dataflow")

### Setup a consumer for testing our dataflow. 

Open a new shell window and execute the following commands
```
docker exec -it twitter2kafka_container /bin/bash
```
Start a console consumer to check the incoming dataflow in Kafka
```
/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic twitter
```

The Twitter data stream can be seen in JSON format:

![alt text](https://cloud.githubusercontent.com/assets/363452/26026242/200afdf0-37f8-11e7-96b4-d4b8210f5d3e.png "Setup a consumer for testing our dataflow.")


### Delete the docker container
```
docker rm -f twitter2kafka_container
```

## The Dockerfile

```docker
# based on input by: Guido Schmutz <@gschmutz>

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
```

### And now let see the Dockerfile step by step: 

```docker
FROM            trivadisbds/base
```
The parent image is the trivadisbds/base image, which is a RedHat image whith Java installation

```docker
ENV             NIFI_DIST_MIRROR             http://mirror.cc.columbia.edu/pub/software/apache/nifi
ENV             NIFI_HOME                    /opt/nifi
ENV             NIFI_VERSION                 1.2.0

ENV             KAFKA_DIST_MIRROR             http://tux.rainside.sk/apache/kafka
ENV             KAFKA_HOME                    /opt/kafka
ENV             KAFKA_VERSION                 0.10.1.0
ENV             SCALA_VERSION                 2.11
```

Environmental variables can be (must be?) set up for the container, that (AP: the environmental variables) contains the URL, version and home for products. With this solution the Dockerfile can be maintained easier.


```docker
RUN             mkdir -p ${NIFI_HOME} && \
                curl ${NIFI_DIST_MIRROR}/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.tar.gz | tar xvz -C ${NIFI_HOME} --strip-components=1 && \
                sed -i -e "s|^nifi.ui.banner.text=.*$|nifi.ui.banner.text=Trivadisbds Docker NiFi ${NIFI_VERSION}|" ${NIFI_HOME}/conf/nifi.properties
```

Download and extracting the Apache Nifi software
```docker
RUN             wget -c ${KAFKA_DIST_MIRROR}/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                tar -xzvf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
                mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt && \
                ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}/ ${KAFKA_HOME}
```

Downloading and extracting the Apache Kafka software
```docker
RUN             echo '#!/bin/bash' > /usr/bin/start-kafka.sh && \
                echo "cd ${KAFKA_HOME}" >> /usr/bin/start-kafka.sh && \
                echo "bin/zookeeper-server-start.sh config/zookeeper.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "bin/kafka-server-start.sh config/server.properties & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "${NIFI_HOME}/bin/nifi.sh run & > ~/output.log" >> /usr/bin/start-kafka.sh && \
                echo "tail -f ~/output.log" >> /usr/bin/start-kafka.sh  && \
                chmod +x /usr/bin/start-kafka.sh
```
This application builds a shell file, that contains all the execute commands are needed to execute Kafka and Nifi parallel.
